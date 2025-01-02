defmodule AlgoraWeb.Org.BountyHook do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.LiveView

  alias Algora.Bounties

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :handle_create_bounty, :handle_event, &handle_create_bounty/3)}
  end

  defp handle_create_bounty("create_bounty", %{"github_issue_url" => url, "amount" => amount}, socket) do
    %{current_user: creator, current_org: owner} = socket.assigns

    case Bounties.create_bounty(creator, owner, url, amount) do
      {:ok, _bounty} ->
        {:halt,
         socket
         |> put_flash(:info, "Bounty created successfully")
         |> push_navigate(to: "/org/#{owner.handle}/bounties")}

      {:error, changeset} ->
        {:halt,
         socket
         |> put_flash(:error, "Error creating bounty")
         |> assign(:new_bounty_form, to_form(changeset))}
    end
  end

  defp handle_create_bounty(_event, _params, socket), do: {:cont, socket}
end
