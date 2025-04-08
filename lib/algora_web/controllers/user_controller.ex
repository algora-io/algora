defmodule AlgoraWeb.UserController do
  use AlgoraWeb, :controller

  def index(conn, params) do
    dbg(params)
    redirect(conn, to: "/#{params["handle"]}/dashboard")
  end
end
