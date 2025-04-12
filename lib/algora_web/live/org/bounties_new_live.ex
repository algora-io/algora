defmodule AlgoraWeb.Org.BountiesNewLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Github
  alias Algora.Payments
  alias AlgoraWeb.Forms.BountyForm

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    org = socket.assigns.current_org

    open_bounties =
      Bounties.list_bounties(
        owner_id: org.id,
        status: :open,
        limit: page_size(),
        current_user: socket.assigns[:current_user]
      )

    top_earners = Accounts.list_developers(org_id: org.id, limit: 10, earnings_gt: Money.zero(:USD))
    stats = Bounties.fetch_stats(org_id: org.id, current_user: socket.assigns[:current_user])
    transactions = Payments.list_hosted_transactions(org.id, limit: page_size())

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
    end

    total_awarded_subtext =
      [
        "#{stats.rewarded_bounties_count} #{ngettext("bounty", "bounties", stats.rewarded_bounties_count)}",
        if stats.rewarded_tips_count > 0 do
          "#{stats.rewarded_tips_count} #{ngettext("tip", "tips", stats.rewarded_tips_count)}"
        end,
        if stats.rewarded_contracts_count > 0 do
          "#{stats.rewarded_contracts_count} #{ngettext("contract", "contracts", stats.rewarded_contracts_count)}"
        end
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" / ")

    socket =
      socket
      |> assign(:org, org)
      |> assign(:has_fresh_token?, Accounts.has_fresh_token?(socket.assigns.current_user))
      |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
      |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
      |> assign(:page_title, org.name)
      |> assign(:open_bounties, open_bounties)
      |> assign(:transactions, transactions)
      |> assign(:top_earners, top_earners)
      |> assign(:stats, stats)
      |> assign(:total_awarded_subtext, total_awarded_subtext)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <!-- Org Header -->
      <div class="rounded-xl border bg-card p-6 text-card-foreground">
        <div class="flex flex-col gap-6 md:flex-row">
          <div class="flex-shrink-0">
            <.avatar class="h-12 w-12 md:h-16 md:w-16">
              <.avatar_image src={@org.avatar_url} alt={@org.name} />
            </.avatar>
          </div>

          <div class="flex-1 space-y-2">
            <div>
              <h1 class="text-2xl font-bold">{@org.name}</h1>
              <p class="mt-1 text-muted-foreground">{@org.bio}</p>
            </div>

            <div class="flex gap-4 items-center">
              <%= for {platform, icon} <- social_links(),
                      url = social_link(@org, platform),
                      not is_nil(url) do %>
                <.link href={url} target="_blank" class="text-muted-foreground hover:text-foreground">
                  <.icon name={icon} class="size-5" />
                </.link>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6 grid grid-cols-1 gap-6 md:grid-cols-4">
        <.stat_card
          title="Open Bounties"
          value={Money.to_string!(@stats.open_bounties_amount)}
          subtext={"#{@stats.open_bounties_count} bounties"}
          navigate={~p"/#{@org.handle}/bounties?status=open"}
          icon="tabler-diamond"
        />
        <.stat_card
          title="Total Awarded"
          value={Money.to_string!(@stats.total_awarded_amount)}
          subtext={@total_awarded_subtext}
          navigate={~p"/#{@org.handle}/bounties?status=completed"}
          icon="tabler-gift"
        />
        <.stat_card
          title="Solvers"
          value={@stats.solvers_count}
          subtext={"+#{@stats.solvers_diff} from last month"}
          navigate={~p"/#{@org.handle}/leaderboard"}
          icon="tabler-user-code"
        />
        <.stat_card
          title="Members"
          value={@stats.members_count}
          subtext=""
          navigate={~p"/#{@org.handle}/team"}
          icon="tabler-users"
        />
      </div>

      <.section>
        {create_bounty(assigns)}
      </.section>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <!-- Bounties Section -->
        <div class="space-y-4 rounded-xl border bg-card p-6">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Open Bounties</h2>
            <.link
              href={~p"/#{@org.handle}/bounties?status=open"}
              class="text-sm text-muted-foreground hover:underline"
            >
              View all
            </.link>
          </div>
          <div class="relative -ml-4 w-full overflow-auto scrollbar-thin">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for bounty <- @open_bounties do %>
                  <tr class="h-10 border-b transition-colors hover:bg-muted/10">
                    <td class="p-4 py-0 align-middle">
                      <div class="flex items-center gap-4">
                        <div class="font-display shrink-0 whitespace-nowrap text-base font-semibold text-success">
                          {Money.to_string!(bounty.amount)}
                        </div>

                        <.link
                          href={Bounty.url(bounty)}
                          class="max-w-[400px] truncate text-sm text-foreground hover:underline"
                        >
                          {bounty.ticket.title}
                        </.link>

                        <div class="flex shrink-0 items-center gap-1 whitespace-nowrap text-sm text-muted-foreground">
                          <.icon name="tabler-chevron-right" class="h-4 w-4" />
                          <.link href={Bounty.url(bounty)} class="hover:underline">
                            {Bounty.path(bounty)}
                          </.link>
                        </div>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
        <!-- Completed Bounties -->
        <div class="space-y-4 rounded-xl border bg-card p-6">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Completed Bounties</h2>
            <.link
              href={~p"/#{@org.handle}/bounties?status=completed"}
              class="text-sm text-muted-foreground hover:underline"
            >
              View all
            </.link>
          </div>
          <div class="relative -ml-4 w-full overflow-auto scrollbar-thin">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for %{transaction: transaction, ticket: ticket} <- @transactions do %>
                  <tr class="h-10 border-b transition-colors hover:bg-muted/10">
                    <td class="p-4 py-0 align-middle">
                      <div class="flex items-center gap-4">
                        <div class="font-display shrink-0 whitespace-nowrap text-base font-semibold text-success">
                          {Money.to_string!(transaction.net_amount)}
                        </div>

                        <.link
                          href={
                            if ticket.repository,
                              do:
                                "https://github.com/#{ticket.repository.user.provider_login}/#{ticket.repository.name}/issues/#{ticket.number}",
                              else: ticket.url
                          }
                          class="max-w-[400px] truncate text-sm text-foreground hover:underline"
                        >
                          {ticket.title}
                        </.link>

                        <div class="flex shrink-0 items-center gap-1 whitespace-nowrap text-sm text-muted-foreground">
                          <.icon name="tabler-chevron-right" class="h-4 w-4" />
                          <.link
                            href={
                              if ticket.repository,
                                do:
                                  "https://github.com/#{ticket.repository.user.provider_login}/#{ticket.repository.name}/issues/#{ticket.number}",
                                else: ticket.url
                            }
                            class="hover:underline"
                          >
                            {Bounty.path(%{ticket: ticket})}
                          </.link>
                        </div>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="space-y-4">
        <h2 class="text-lg font-semibold">Top Earners</h2>
        <div class="rounded-xl border bg-card">
          <%= for {earner, idx} <- Enum.with_index(@top_earners) do %>
            <div class="flex items-center gap-4 border-b p-4 last:border-0">
              <div class="w-8 flex-shrink-0 text-center font-mono text-muted-foreground">
                #{idx + 1}
              </div>
              <.link navigate={User.url(earner)} class="flex flex-1 items-center gap-3">
                <.avatar class="h-8 w-8">
                  <.avatar_image src={earner.avatar_url} alt={earner.name} />
                </.avatar>
                <div>
                  <div class="font-medium">
                    {earner.name} {Algora.Misc.CountryEmojis.get(earner.country)}
                  </div>
                  <div class="text-sm text-muted-foreground">@{User.handle(earner)}</div>
                </div>
              </.link>
              <div class="font-display flex-shrink-0 font-medium text-success">
                {Money.to_string!(earner.total_earned)}
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:authenticated, user}, socket) do
    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:current_context, Accounts.get_last_context_user(user))
      |> assign(:all_contexts, Accounts.get_contexts(user))
      |> assign(:has_fresh_token?, true)

    case socket.assigns.pending_action do
      {event, params} ->
        socket = assign(socket, :pending_action, nil)
        handle_event(event, params, socket)

      nil ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create_bounty" = event, %{"bounty_form" => params} = unsigned_params, socket) do
    if socket.assigns.has_fresh_token? do
      changeset = %BountyForm{} |> BountyForm.changeset(params) |> Map.put(:action, :validate)

      amount = get_field(changeset, :amount)
      ticket_ref = get_field(changeset, :ticket_ref)

      with %{valid?: true} <- changeset,
           {:ok, _bounty} <-
             Bounties.create_bounty(
               %{
                 creator: socket.assigns.current_user,
                 owner: socket.assigns.current_context,
                 amount: amount,
                 ticket_ref: %{
                   owner: ticket_ref.owner,
                   repo: ticket_ref.repo,
                   number: ticket_ref.number
                 }
               },
               visibility: get_field(changeset, :visibility),
               shared_with: get_field(changeset, :shared_with)
             ) do
        {:noreply, put_flash(socket, :info, "Bounty created")}
      else
        %{valid?: false} ->
          {:noreply, assign(socket, :bounty_form, to_form(changeset))}

        {:error, :already_exists} ->
          {:noreply, put_flash(socket, :warning, "You already have a bounty for this ticket")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Something went wrong")}
      end
    else
      {:noreply,
       socket
       |> assign(:pending_action, {event, unsigned_params})
       |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp create_bounty(assigns) do
    ~H"""
    <div class="border ring-1 ring-transparent rounded-xl overflow-hidden">
      <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-emerald-400">
        <div class="p-4 sm:p-6">
          <div class="text-2xl font-semibold text-foreground">
            Fund any {@org.name} issue<br class="block sm:hidden" />
            <span class="text-success drop-shadow-[0_1px_5px_#34d39980]">
              in seconds
            </span>
          </div>
          <div class="pt-1 text-base font-medium text-muted-foreground">
            Prioritize issues and reward contributors when work is done
          </div>
          <.simple_form for={@bounty_form} phx-submit="create_bounty">
            <div class="flex flex-col gap-6 pt-6">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                <.input
                  label="Issue URL"
                  field={@bounty_form[:url]}
                  placeholder={"https://github.com/#{@org.provider_login}/repo/issues/1337"}
                />
                <.input label="Amount" icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
              </div>
              <p class="text-sm text-muted-foreground">
                <.icon name="tabler-sparkles" class="size-4 text-current mr-1" /> Comment
                <code class="px-1 py-0.5 text-success">/bounty $100</code>
                on GitHub issues
              </p>
              <div class="flex justify-end gap-4">
                <.button>Submit</.button>
              </div>
            </div>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  defp social_links do
    [
      {:website, "tabler-world"},
      {:github, "github"},
      {:twitter, "tabler-brand-x"},
      {:youtube, "tabler-brand-youtube"},
      {:twitch, "tabler-brand-twitch"},
      {:discord, "tabler-brand-discord"},
      {:slack, "tabler-brand-slack"},
      {:linkedin, "tabler-brand-linkedin"}
    ]
  end

  defp social_link(user, :github), do: if(login = user.provider_login, do: "https://github.com/#{login}")
  defp social_link(user, platform), do: Map.get(user, :"#{platform}_url")

  defp page_size, do: 5
end
