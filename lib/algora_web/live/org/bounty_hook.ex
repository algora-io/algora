defmodule AlgoraWeb.Org.BountyHook do
  @moduledoc false
  use Phoenix.Component

  import Ecto.Changeset
  import Phoenix.LiveView

  alias Algora.Bounties
  alias Algora.Parser

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :handle_create_bounty, :handle_event, &handle_create_bounty/3)}
  end

  defp handle_create_bounty("create_bounty", %{"github_issue_url" => url, "amount" => amount}, socket) do
    %{current_user: creator, current_org: owner} = socket.assigns

    # TODO: use AlgoraWeb.Community.DashboardLive.BountyForm
    with {:ok, [ticket_ref: ticket_ref], _, _, _, _} <- Parser.full_ticket_ref(url),
         {:ok, _bounty} <-
           Bounties.create_bounty(%{creator: creator, owner: owner, ticket_ref: ticket_ref, amount: amount}) do
      {:halt,
       socket
       |> put_flash(:info, "Bounty created successfully")
       |> push_navigate(to: "/org/#{owner.handle}/bounties")}
    else
      {:error, :already_exists} ->
        {:halt, put_flash(socket, :warning, "You have already created a bounty for this ticket")}

      {:error, _reason} ->
        changeset = add_error(socket.assigns.new_bounty_form.changeset, :github_issue_url, "Invalid URL")
        {:halt, assign(socket, :new_bounty_form, to_form(changeset))}
    end
  end

  defp handle_create_bounty(_event, _params, socket), do: {:cont, socket}
end
