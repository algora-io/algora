defmodule Algora.ScreenshotQueue do
  @moduledoc false
  use GenServer

  require Logger

  @timeout 10_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def generate_image(url, opts) do
    GenServer.call(__MODULE__, {:generate_image, url, opts}, opts[:timeout] || @timeout)
  end

  @impl true
  def init(:ok) do
    {:ok, :no_state_needed}
  end

  @impl true
  def handle_call({:generate_image, url, opts}, _from, state) do
    result =
      try do
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

        Task.await(task, opts[:timeout] || @timeout)
      catch
        :exit, {:timeout, _} -> {:error, :timeout}
      end

    {:reply, result, state}
  end

  defp build_opts(url, options) do
    options
    |> Keyword.take([:type, :path, :width, :height, :scale_factor])
    |> Enum.reduce([url], fn {key, value}, result ->
      result ++ [String.replace("--#{key}=#{value}", "_", "-")]
    end)
  end
end
