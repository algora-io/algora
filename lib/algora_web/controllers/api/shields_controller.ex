defmodule AlgoraWeb.API.ShieldsController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias Algora.Bounties

  def bounties(conn, %{"org_handle" => org_handle, "status" => status}) do
    case Accounts.fetch_user_by(handle: org_handle) do
      {:ok, org} ->
        stats = Bounties.fetch_stats(org_id: org.id)

        {label, message, label_color} =
          case status do
            "open" ->
              {
                "💎 Open Bounties",
                Money.to_string!(stats.open_bounties_amount, no_fraction_if_integer: true),
                "4f46e5"
              }

            "completed" ->
              {
                "💰 Rewarded Bounties",
                Money.to_string!(stats.total_awarded_amount, no_fraction_if_integer: true),
                "15803d"
              }
          end

        json(conn, %{
          schemaVersion: 1,
          label: label,
          message: message,
          color: "grey",
          labelColor: label_color
        })

      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Organization not found"})
    end
  end
end
