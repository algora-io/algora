defmodule AlgoraWeb.Plugs.RewriteObserveJSPlug do
  @moduledoc false

  defdelegate init(opts), to: ReverseProxyPlug
  defdelegate call(conn, opts), to: ReverseProxyPlug
end
