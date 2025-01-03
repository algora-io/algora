defmodule AlgoraWeb.NotFoundError do
  @moduledoc false
  defexception message: "not found", plug_status: 404
end
