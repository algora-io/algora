defmodule AlgoraWeb.Plugs.RewriteIngestPlug do
  defdelegate init(opts), to: ReverseProxyPlug
  defdelegate call(conn, opts), to: ReverseProxyPlug
end
