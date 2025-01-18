defmodule AlgoraWeb.ActivityController do
  use AlgoraWeb, :controller

  alias Algora.Activities

  def get(conn, %{"table_prefix" => table, "activity_id" => id} = _params) do
    with {:ok, url} <- Activities.assoc_url("#{table}_activities", id) do
      redirect(conn, external: url)
    end
  end
end
