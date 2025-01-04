defmodule AlgoraWeb.StripeCallbackController do
  use AlgoraWeb, :controller

  alias Algora.Payments

  def refresh(conn, params), do: refresh_stripe_account(conn, params)
  def return(conn, params), do: refresh_stripe_account(conn, params)

  defp refresh_stripe_account(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> redirect(to: ~p"/auth/login")
        |> halt()

      current_user ->
        case Payments.refresh_stripe_account(current_user.id) do
          {:ok, _account} ->
            redirect(conn, to: ~p"/user/transactions")

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Failed to refresh Stripe account")
            |> redirect(to: ~p"/user/transactions")
        end
    end
  end
end
