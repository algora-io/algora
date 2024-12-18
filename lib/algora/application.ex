defmodule Algora.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},
      AlgoraWeb.Telemetry,
      Algora.Repo,
      {DNSCluster, query: Application.get_env(:algora, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Algora.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Algora.Finch},
      Algora.Stargazer,
      # Start to serve requests, typically the last entry
      AlgoraWeb.Endpoint
    ]

    children =
      case Application.get_env(:algora, :cloudflare_tunnel) do
        nil -> children
        tunnel -> children ++ [{Algora.Tunnel, tunnel}]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Algora.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlgoraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
