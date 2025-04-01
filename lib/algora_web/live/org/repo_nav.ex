defmodule AlgoraWeb.Org.RepoNav do
  @moduledoc false
  use Phoenix.Component
  use AlgoraWeb, :verified_routes

  import Ecto.Changeset
  import Phoenix.LiveView

  alias Algora.Bounties
  alias Algora.Organizations
  alias Algora.Organizations.Member
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.OrgAuth

  require Logger

  def on_mount(:default, %{"repo_owner" => repo_owner} = params, _session, socket) do
    current_user = socket.assigns[:current_user]
    current_org = Organizations.get_org_by(provider_login: repo_owner, provider: "github")
    current_user_role = OrgAuth.get_user_role(current_user, current_org)

    main_bounty_form =
      if Member.can_create_bounty?(current_user_role) do
        to_form(BountyForm.changeset(%BountyForm{}, %{}))
      end

    {:cont,
     socket
     |> assign(:screenshot?, not is_nil(params["screenshot"]))
     |> assign(:main_bounty_form, main_bounty_form)
     |> assign(:main_bounty_form_open?, false)
     |> assign(:current_org, current_org)
     |> assign(:current_user_role, current_user_role)
     |> assign(:nav, nav_items(current_org.handle, current_user_role))
     |> assign(:contacts, [])
     |> attach_hook(:active_tab, :handle_params, &handle_active_tab_params/3)
     |> attach_hook(:handle_event, :handle_event, &handle_event/3)}
  end

  defp handle_event("create_bounty_main", %{"bounty_form" => params}, socket) do
    changeset = BountyForm.changeset(%BountyForm{}, params)

    case apply_action(changeset, :save) do
      {:ok, data} ->
        bounty_res =
          case data.type do
            :github ->
              Bounties.create_bounty(
                %{
                  creator: socket.assigns.current_user,
                  owner: socket.assigns.current_org,
                  amount: data.amount,
                  ticket_ref: %{
                    owner: data.ticket_ref.owner,
                    repo: data.ticket_ref.repo,
                    number: data.ticket_ref.number
                  }
                },
                visibility: get_field(changeset, :visibility),
                shared_with: get_field(changeset, :shared_with)
              )

            :custom ->
              Bounties.create_bounty(
                %{
                  creator: socket.assigns.current_user,
                  owner: socket.assigns.current_org,
                  amount: data.amount,
                  title: data.title,
                  description: data.description
                },
                visibility: get_field(changeset, :visibility),
                shared_with: get_field(changeset, :shared_with)
              )
          end

        case bounty_res do
          {:ok, bounty} ->
            to =
              case data.type do
                :github ->
                  ~p"/#{data.ticket_ref.owner}/#{data.ticket_ref.repo}/issues/#{data.ticket_ref.number}"

                :custom ->
                  ~p"/org/#{socket.assigns.current_org.handle}/bounties/#{bounty.id}"
              end

            {:cont, redirect(socket, to: to)}

          {:error, :already_exists} ->
            {:cont, put_flash(socket, :warning, "You already have a bounty for this ticket")}

          {:error, reason} ->
            Logger.error("Failed to create bounty: #{inspect(reason)}")
            {:cont, put_flash(socket, :error, "Something went wrong")}
        end

      {:error, changeset} ->
        {:cont, assign(socket, :main_bounty_form, to_form(changeset))}
    end
  end

  defp handle_event("open_main_bounty_form", _params, socket) do
    {:cont, assign(socket, :main_bounty_form_open?, true)}
  end

  defp handle_event("close_main_bounty_form", _params, socket) do
    {:cont, assign(socket, :main_bounty_form_open?, false)}
  end

  defp handle_event(_event, _params, socket) do
    {:cont, socket}
  end

  defp handle_active_tab_params(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {AlgoraWeb.Org.DashboardLive, _} -> :dashboard
        {AlgoraWeb.Org.HomeLive, _} -> :home
        {AlgoraWeb.Org.BountiesLive, _} -> :bounties
        {AlgoraWeb.Org.ProjectsLive, _} -> :projects
        {AlgoraWeb.Project.ViewLive, _} -> :projects
        {AlgoraWeb.Org.SettingsLive, _} -> :settings
        {AlgoraWeb.Org.MembersLive, _} -> :members
        {_, _} -> nil
      end

    {:cont, assign(socket, :active_tab, active_tab)}
  end

  def nav_items(org_handle, current_user_role) do
    [
      %{
        title: "Overview",
        items: build_nav_items(org_handle, current_user_role)
      }
    ]
  end

  defp build_nav_items(org_handle, current_user_role) do
    Enum.filter(
      [
        %{
          href: "/org/#{org_handle}",
          tab: :dashboard,
          icon: "tabler-sparkles",
          label: "Dashboard",
          roles: [:admin, :mod]
        },
        %{
          href: "/org/#{org_handle}/home",
          tab: :home,
          icon: "tabler-home",
          label: "Home",
          roles: [:admin, :mod, :expert, :none]
        },
        %{
          href: "/org/#{org_handle}/bounties",
          tab: :bounties,
          icon: "tabler-diamond",
          label: "Bounties",
          roles: [:admin, :mod, :expert, :none]
        },
        %{
          href: "/org/#{org_handle}/leaderboard",
          tab: :leaderboard,
          icon: "tabler-trophy",
          label: "Leaderboard",
          roles: [:admin, :mod, :expert, :none]
        },
        %{
          href: "/org/#{org_handle}/team",
          tab: :team,
          icon: "tabler-users",
          label: "Team",
          roles: [:admin, :mod, :expert, :none]
        },
        %{
          href: "/org/#{org_handle}/transactions",
          tab: :transactions,
          icon: "tabler-credit-card",
          label: "Transactions",
          roles: [:admin]
        },
        %{
          href: "/org/#{org_handle}/settings",
          tab: :settings,
          icon: "tabler-settings",
          label: "Settings",
          roles: [:admin]
        }
      ],
      fn item -> current_user_role in item[:roles] end
    )
  end
end
