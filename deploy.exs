defmodule Algora.GracefulDeploy do
  @moduledoc false

  @default_app "algora"
  @default_process_group "app"
  @default_drain_seconds 30
  @default_health_timeout 180
  @default_shutdown_timeout 120
  @fly System.get_env("FLY_BIN", "fly")
  @prepare_command ~s(/app/bin/algora rpc "Algora.Release.prepare_for_deploy()")

  def main(argv) do
    {opts, args, invalid} =
      OptionParser.parse(argv,
        aliases: [a: :app, g: :process_group],
        switches: [
          app: :string,
          process_group: :string,
          drain_seconds: :integer,
          health_timeout: :integer,
          shutdown_timeout: :integer
        ]
      )

    if invalid != [] or length(args) != 1 do
      usage()
    end

    [new_image_ref] = args
    app = opts[:app] || System.get_env("FLY_APP_NAME") || @default_app
    process_group = opts[:process_group] || @default_process_group
    drain_seconds = opts[:drain_seconds] || @default_drain_seconds
    health_timeout = opts[:health_timeout] || @default_health_timeout
    shutdown_timeout = opts[:shutdown_timeout] || @default_shutdown_timeout

    old_machines = list_process_machines(app, process_group)
    old_count = length(old_machines)

    if old_count == 0 do
      raise "No machines found for #{app}/#{process_group}"
    end

    log_machines("old machines", old_machines)

    scale_count(app, process_group, old_count * 2)

    new_machines =
      app
      |> wait_for_machine_count(process_group, old_count * 2)
      |> Enum.reject(&known_machine?(&1, old_machines))

    log_machines("new machines", new_machines)

    Enum.each(new_machines, fn machine ->
      run!(
        "update #{machine["id"]}",
        ["machine", "update", machine["id"], "--app", app, "--image", new_image_ref, "--yes"]
      )
    end)

    wait_for_machines_healthy(app, new_machines, health_timeout)

    Enum.each(old_machines, fn machine ->
      IO.puts("Marking #{machine["id"]} unhealthy and pausing local queues")
      run!("prepare #{machine["id"]}", ["machine", "exec", machine["id"], @prepare_command, "--app", app])
    end)

    IO.puts("Waiting #{drain_seconds}s for Fly checks to stop routing to old machines")
    Process.sleep(:timer.seconds(drain_seconds))

    Enum.each(old_machines, fn machine ->
      IO.puts("Stopping #{machine["id"]} with SIGTERM")

      run!(
        "stop #{machine["id"]}",
        [
          "machine",
          "stop",
          machine["id"],
          "--app",
          app,
          "--signal",
          "SIGTERM",
          "--timeout",
          to_string(shutdown_timeout),
          "--wait-timeout",
          "#{shutdown_timeout}s"
        ]
      )

      run!("destroy #{machine["id"]}", ["machine", "destroy", machine["id"], "--app", app, "--force"])
    end)

    scale_count(app, process_group, old_count)
  end

  defp list_process_machines(app, process_group) do
    {json, 0} = run!("list machines", ["machine", "list", "--app", app, "--json"])

    json
    |> Jason.decode!()
    |> Enum.filter(&(process_group(&1) == process_group))
  end

  defp wait_for_machine_count(app, process_group, count, attempts \\ 12)

  defp wait_for_machine_count(app, process_group, count, 0) do
    machines = list_process_machines(app, process_group)
    raise "Expected #{count} #{process_group} machines, found #{length(machines)}"
  end

  defp wait_for_machine_count(app, process_group, count, attempts) do
    machines = list_process_machines(app, process_group)

    if length(machines) >= count do
      machines
    else
      Process.sleep(:timer.seconds(5))
      wait_for_machine_count(app, process_group, count, attempts - 1)
    end
  end

  defp wait_for_machines_healthy(app, machines, timeout_seconds) do
    Enum.each(machines, fn machine ->
      wait_for_machine_healthy(app, machine["id"], timeout_seconds)
    end)
  end

  defp wait_for_machine_healthy(app, machine_id, timeout_seconds) do
    deadline = System.monotonic_time(:millisecond) + :timer.seconds(timeout_seconds)

    wait_for_machine_healthy_until(app, machine_id, deadline)
  end

  defp wait_for_machine_healthy_until(app, machine_id, deadline) do
    status = machine_status(app, machine_id)

    if machine_healthy?(status) do
      IO.puts("Replacement machine #{machine_id} is healthy")
    else
      if System.monotonic_time(:millisecond) >= deadline do
        raise """
        Replacement machine #{machine_id} did not become healthy before the timeout.
        Refusing to drain old machines while the new image is not passing Fly checks.
        """
      end

      IO.puts("Waiting for replacement machine #{machine_id} to pass Fly checks")
      Process.sleep(:timer.seconds(5))
      wait_for_machine_healthy_until(app, machine_id, deadline)
    end
  end

  defp machine_status(app, machine_id) do
    {json, 0} = run!("status #{machine_id}", ["machine", "status", machine_id, "--app", app, "--json"])
    Jason.decode!(json)
  end

  defp machine_healthy?(status) do
    machine_started?(status) and fly_checks_passing?(status)
  end

  defp machine_started?(%{"state" => "started"}), do: true
  defp machine_started?(%{"instance" => %{"state" => "started"}}), do: true
  defp machine_started?(_status), do: false

  defp fly_checks_passing?(status) do
    statuses =
      status
      |> Map.take(["checks"])
      |> check_statuses()

    statuses != [] and Enum.all?(statuses, &(&1 in ["passing", "passed"]))
  end

  defp check_statuses(%{"status" => status} = data) when is_binary(status) do
    child_statuses =
      data
      |> Map.drop(["status"])
      |> check_statuses()

    [status | child_statuses]
  end

  defp check_statuses(map) when is_map(map) do
    map
    |> Map.values()
    |> Enum.flat_map(&check_statuses/1)
  end

  defp check_statuses(list) when is_list(list) do
    Enum.flat_map(list, &check_statuses/1)
  end

  defp check_statuses(_value), do: []

  defp scale_count(app, process_group, count) do
    run!("scale #{process_group}=#{count}", [
      "scale",
      "count",
      "#{process_group}=#{count}",
      "--app",
      app,
      "--yes"
    ])
  end

  defp known_machine?(machine, machines) do
    Enum.any?(machines, &(&1["id"] == machine["id"]))
  end

  defp process_group(machine) do
    get_in(machine, ["config", "metadata", "fly_process_group"]) ||
      get_in(machine, ["config", "env", "FLY_PROCESS_GROUP"]) ||
      machine["process_group"] ||
      @default_process_group
  end

  defp log_machines(label, machines) do
    IO.puts(label)

    machines
    |> Enum.map(& &1["id"])
    |> IO.inspect(limit: :infinity)
  end

  defp run!(label, args) do
    IO.puts("$ #{@fly} #{Enum.join(args, " ")}")

    case System.cmd(@fly, args, stderr_to_stdout: true) do
      {output, 0} -> {output, 0}
      {output, status} -> raise "#{label} failed with status #{status}\n#{output}"
    end
  end

  defp usage do
    IO.puts("""
    Usage:
      mix run deploy.exs registry.fly.io/algora:deployment-xxxx

    Options:
      --app, -a             Fly app name (defaults to FLY_APP_NAME or algora)
      --process-group, -g   Fly process group to rotate (defaults to app)
      --drain-seconds       Seconds to wait after marking old machines unhealthy
      --health-timeout      Seconds to wait for replacement machines to pass checks
      --shutdown-timeout    Seconds Fly should allow SIGTERM shutdown before SIGKILL
    """)

    System.halt(1)
  end
end

Algora.GracefulDeploy.main(System.argv())
