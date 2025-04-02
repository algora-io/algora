defmodule AlgoraWeb.Plugs.RewriteAssetsPlug do
  @moduledoc false
  alias AlgoraWeb.Plugs.RuntimeRewritePlug

  defdelegate init(opts), to: RuntimeRewritePlug
  defdelegate call(conn, opts), to: RuntimeRewritePlug
end
