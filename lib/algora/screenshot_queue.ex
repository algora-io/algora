defmodule Algora.ScreenshotQueue do
  @moduledoc false
  use GenServer

  require Logger

  @timeout 30_000
  @max_concurrent_tasks 3

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

  @impl true
  def init(:ok) do
    {:ok, %{active_tasks: %{}, queue: :queue.new(), waiting: %{}}}
  end

  @impl true
  def handle_call({:generate_image, url, opts}, from, state) do
    active_count = map_size(state.active_tasks)
    :telemetry.execute([:algora, :screenshot_queue], %{length: :queue.len(state.queue)})
    :telemetry.execute([:algora, :screenshot_queue], %{active_count: active_count})

    if active_count < @max_concurrent_tasks do
      {_task, new_state} = start_task(url, opts, from, state)
      {:noreply, new_state}
    else
      queue = :queue.in({url, opts, from}, state.queue)
      {:noreply, %{state | queue: queue}}
    end
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
        try do
          puppeteer_path = Path.join([:code.priv_dir(:algora), "puppeteer", "puppeteer-img.js"])

          case System.cmd("node", [puppeteer_path] ++ build_opts(url, opts)) do
            {_, 127} -> {:error, :invalid_exec_path}
            {cmd_response, _} -> {:ok, cmd_response}
          end
        rescue
          e in ErlangError ->
            %ErlangError{original: error} = e

            case error do
              :enoent -> {:error, :invalid_exec_path}
            end
        end
      end)

    {task, %{state | active_tasks: Map.put(state.active_tasks, task.ref, from)}}
  end

  defp build_opts(url, options) do
    options
    |> Keyword.take([:type, :path, :width, :height, :scale_factor])
    |> Enum.reduce([url], fn {key, value}, result ->
      result ++ [String.replace("--#{key}=#{value}", "_", "-")]
    end)
  end
end
