defmodule AlgoraWeb.Plugs.RewriteAssetsPlug do
  defdelegate init(opts), to: ReverseProxyPlug
  defdelegate call(conn, opts), to: ReverseProxyPlug
end
