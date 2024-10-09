defmodule AlgoraWeb.Nav do
  use Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:region, System.get_env("FLY_REGION") || "iad")}
  end
end
