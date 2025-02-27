defmodule AlgoraWeb.TipController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Repo
  alias Algora.Workspace
  alias AlgoraWeb.UserAuth

  def create(conn, %{"amount" => amount, "recipient" => recipient} = params) do
    ticket_ref = extract_ticket_ref(params)

    owner_res =
      case params["org_id"] do
        nil -> get_current_user(conn)
        org_id -> Repo.fetch(User, org_id)
      end

    with {:ok, current_user} <- get_current_user(conn),
         %Money{} = amount <- Money.new(:USD, amount),
         {:ok, token} <- Accounts.get_access_token(current_user),
         {:ok, recipient_user} <- Workspace.ensure_user(token, recipient),
         {:ok, owner} <- owner_res,
         {:ok, checkout_url} <-
           Bounties.create_tip(
             %{
               creator: current_user,
               owner: owner,
               recipient: recipient_user,
               amount: amount
             },
             if(ticket_ref, do: [ticket_ref: ticket_ref], else: [])
           ) do
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

  defp extract_ticket_ref(%{"owner" => owner, "repo" => repo, "number" => number}) do
    case Integer.parse(number) do
      {number, ""} -> [owner: owner, repo: repo, number: number]
      _ -> nil
    end
  end

  defp extract_ticket_ref(_), do: nil

  defp get_current_user(conn) do
    case conn.assigns.current_user do
      nil -> {:error, :unauthorized}
      user -> {:ok, user}
    end
  end
end
