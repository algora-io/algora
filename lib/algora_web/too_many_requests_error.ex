defmodule AlgoraWeb.TooManyRequestsError do
  @moduledoc false
  defexception message: "too many requests", plug_status: 429
end
