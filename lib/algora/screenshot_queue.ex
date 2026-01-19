defmodule Algora.ScreenshotQueue do
  @moduledoc false
  use GenServer

  require Logger

  @timeout 30_000
  @max_concurrent_tasks 3
  @max_queue_size 100

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def generate_image(url, opts \\ []) do
    start_time = System.monotonic_time()
    result = GenServer.call(__MODULE__, {:generate_image, url, opts}, opts[:timeout] || @timeout)
    end_time = System.monotonic_time()

    :telemetry.execute([:algora, :screenshot_queue, :generate], %{duration: end_time - start_time})

    result
  end

  def queue_size do
    GenServer.call(__MODULE__, :queue_size)
  end

  def clear_queue do
    GenServer.call(__MODULE__, :clear_queue)
  end

  @impl true
  def init(:ok) do
    {:ok, %{active_tasks: %{}, queue: :queue.new(), waiting: %{}}}
  end

  @impl true
  def handle_call({:generate_image, url, opts}, from, state) do
    path = Keyword.get(opts, :path, "no path")
    Logger.info("Screenshot request: url=#{url} path=#{path}")

    active_count = map_size(state.active_tasks)
    :telemetry.execute([:algora, :screenshot_queue], %{length: :queue.len(state.queue)})
    :telemetry.execute([:algora, :screenshot_queue], %{active_count: active_count})

    if active_count < @max_concurrent_tasks do
      {_task, new_state} = start_task(url, opts, from, state)
      {:noreply, new_state}
    else
      queue = :queue.in({url, opts, from}, state.queue)
      queue = enforce_max_queue_size(queue)
      {:noreply, %{state | queue: queue}}
    end
  end

  @impl true
  def handle_call(:queue_size, _from, state) do
    {:reply, %{queue: :queue.len(state.queue), active: map_size(state.active_tasks)}, state}
  end

  @impl true
  def handle_call(:clear_queue, _from, state) do
    dropped_count = :queue.len(state.queue)
    Logger.info("Clearing screenshot queue, dropping #{dropped_count} items")
    {:reply, {:ok, dropped_count}, %{state | queue: :queue.new()}}
  end

  @impl true
  def handle_info({ref, result}, state) when is_reference(ref) do
    {from, new_active_tasks} = Map.pop(state.active_tasks, ref)
    if is_tuple(from), do: GenServer.reply(from, result)

    case :queue.out(state.queue) do
      {{:value, {url, opts, next_from}}, new_queue} ->
        {_task, new_state} = start_task(url, opts, next_from, %{state | active_tasks: new_active_tasks, queue: new_queue})
        {:noreply, new_state}

      {:empty, _} ->
        {:noreply, %{state | active_tasks: new_active_tasks}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {_from, new_active_tasks} = Map.pop(state.active_tasks, ref)
    {:noreply, %{state | active_tasks: new_active_tasks}}
  end

  defp start_task(url, opts, from, state) do
    task =
      Task.async(fn ->
        try_generate_image(url, opts, 3)
      end)

    {task, %{state | active_tasks: Map.put(state.active_tasks, task.ref, from)}}
  end

  defp enforce_max_queue_size(queue) do
    queue_len = :queue.len(queue)

    if queue_len > @max_queue_size do
      dropped = queue_len - @max_queue_size
      Logger.warning("Screenshot queue exceeded max size (#{queue_len}), dropping #{dropped} oldest items")
      drop_oldest(queue, dropped)
    else
      queue
    end
  end

  defp drop_oldest(queue, 0), do: queue

  defp drop_oldest(queue, count) do
    case :queue.out(queue) do
      {{:value, _}, new_queue} -> drop_oldest(new_queue, count - 1)
      {:empty, queue} -> queue
    end
  end

  defp try_generate_image(url, opts, attempts_left) when attempts_left > 0 do
    puppeteer_path = Path.join([:code.priv_dir(:algora), "puppeteer", "puppeteer-img.js"])

    Logger.info("Running puppeteer command: #{Enum.join([puppeteer_path] ++ build_opts(url, opts), " ")}")

    case System.cmd("node", [puppeteer_path] ++ build_opts(url, opts)) do
      {cmd_response, 0} ->
        {:ok, cmd_response}

      {_, 127} = res ->
        Logger.warning("Puppeteer command failed with #{inspect(res)}")
        {:error, :invalid_exec_path}

      res ->
        Logger.warning("Puppeteer command failed with #{inspect(res)}, attempts left: #{attempts_left - 1}")
        try_generate_image(url, opts, attempts_left - 1)
    end
  rescue
    e in ErlangError ->
      %ErlangError{original: error} = e

      case error do
        :enoent ->
          Logger.warning("Puppeteer command failed with :enoent")
          {:error, :invalid_exec_path}

        _ ->
          Logger.warning("Puppeteer command failed with #{inspect(error)}, attempts left: #{attempts_left - 1}")
          try_generate_image(url, opts, attempts_left - 1)
      end

    error ->
      Logger.warning("Puppeteer command failed with #{inspect(error)}, attempts left: #{attempts_left - 1}")
      try_generate_image(url, opts, attempts_left - 1)
  end

  defp try_generate_image(_url, _opts, 0) do
    {:error, :max_retries_exceeded}
  end

  defp build_opts(url, options) do
    options
    |> Keyword.take([:type, :path, :width, :height, :scale_factor])
    |> Enum.reduce([url], fn {key, value}, result ->
      result ++ ["--#{key}=#{value}"]
    end)
  end
end
