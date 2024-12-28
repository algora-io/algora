defmodule AlgoraWeb.TipController do
  use AlgoraWeb, :controller

  alias Algora.{Bounties, Users, Workspace}
  alias AlgoraWeb.UserAuth

  def create(conn, %{"amount" => amount, "recipient" => recipient} = _params) do
    with {:ok, current_user} <- get_current_user(conn),
         %Money{} = amount <- Money.new(:USD, amount),
         {:ok, token} <- Users.get_access_token(current_user),
         {:ok, recipient_user} <- Workspace.ensure_user(token, recipient),
         {:ok, checkout_url} <-
           Bounties.create_tip(%{
             creator: current_user,
             owner: current_user,
             recipient: recipient_user,
             amount: amount
           }) do
      redirect(conn, external: checkout_url)
    else
      # TODO: just use a plug
      {:error, :unauthorized} ->
        conn
        |> put_session(:user_return_to, conn.request_path <> "?" <> conn.query_string)
        |> put_flash(:error, "You must be logged in to tip")
        |> redirect(to: ~p"/auth/login")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create tip: #{inspect(reason)}")
        |> redirect(to: UserAuth.signed_in_path(conn))
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Missing required parameters")
    |> redirect(to: UserAuth.signed_in_path(conn))
  end

  defp get_current_user(conn) do
    case conn.assigns.current_user do
      nil -> {:error, :unauthorized}
      user -> {:ok, user}
    end
  end
end
