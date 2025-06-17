defmodule AlgoraWeb.User.ProfileLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Payments
  alias Algora.Reviews
  alias Algora.Reviews.Review

  @impl true
  def mount(%{"user_handle" => handle}, _session, socket) do
    case Accounts.fetch_developer_by(handle: handle) do
      {:ok, user} ->
        transactions = Payments.list_received_transactions(user.id, limit: page_size())

        contributions = Algora.Workspace.list_user_contributions([user.id], limit: 20)

        {:ok,
         socket
         |> assign(:user, user)
         |> assign(:page_title, "#{user.name}")
         |> assign(:page_description, "Open source contributions and bounty history of #{user.name}")
         |> assign(:reviews, Reviews.list_reviews(reviewee_id: user.id, limit: 10))
         |> assign(:transactions, to_transaction_rows(transactions))
         |> assign(:has_more_transactions, length(transactions) >= page_size())
         |> assign(:contributions, contributions)}

      {:error, :not_found} ->
        raise AlgoraWeb.NotFoundError
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-6xl space-y-6 p-6">
      <!-- Profile Header -->
      <div class="rounded-xl border bg-card p-6 text-card-foreground">
        <div class="flex flex-col gap-6 md:flex-row">
          <div class="flex-shrink-0">
            <.avatar class="h-12 w-12 md:h-16 md:w-16">
              <.avatar_image src={@user.avatar_url} alt={@user.name} />
            </.avatar>
          </div>

          <div class="flex-1 space-y-4">
            <div>
              <h1 class="text-2xl font-bold">{@user.name}</h1>
              <p class="text-muted-foreground">@{User.handle(@user)}</p>
            </div>

            <p class="max-w-3xl text-foreground whitespace-pre-line">{@user.bio}</p>

            <div class="flex flex-wrap gap-4">
              <%= for tech <- @user.tech_stack do %>
                <.tech_badge tech={tech} />
              <% end %>
            </div>
          </div>
        </div>
      </div>
      <!-- Stats Grid -->
      <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
        <div class="rounded-lg border border-border bg-card p-6">
          <div class="mb-2 flex items-center gap-2">
            <div class="font-display text-2xl font-bold">
              {Money.to_string!(@user.total_earned)}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Total Earnings</div>
        </div>
        <div class="rounded-lg border border-border bg-card p-6">
          <div class="mb-2 flex items-center gap-2">
            <div class="font-display text-2xl font-bold">
              {@user.transactions_count}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Bounties Solved</div>
        </div>
        <div class="rounded-lg border border-border bg-card p-6">
          <div class="mb-2 flex items-center gap-2">
            <div class="font-display text-2xl font-bold">
              {@user.contributed_projects_count}
            </div>
          </div>
          <div class="text-sm text-muted-foreground">Projects Contributed</div>
        </div>
      </div>
      <!-- Replace the entire .tabs section with this: -->
      <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
        <!-- Completed Bounties Column -->
        <div class="space-y-4" id="transactions-container" phx-hook="InfiniteScroll">
          <h2 class="text-lg font-semibold">Completed Bounties</h2>
          <%= if Enum.empty?(@transactions) do %>
            <.card class="text-center">
              <.card_header>
                <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                  <.icon name="tabler-diamond" class="h-8 w-8 text-muted-foreground" />
                </div>
                <.card_title>No bounties yet</.card_title>
                <.card_description>
                  Completed bounties will appear here once this user solves a bounty
                </.card_description>
              </.card_header>
            </.card>
          <% else %>
            <div class="relative -ml-4 w-full overflow-auto">
              <table class="w-full caption-bottom text-sm">
                <tbody>
                  <%= for %{transaction: transaction, ticket: ticket, project: project} <- @transactions do %>
                    <tr class="border-b transition-colors hover:bg-muted/10">
                      <td class="p-4 align-middle">
                        <div class="flex items-start gap-4">
                          <.link navigate={User.url(project)}>
                            <span class="relative flex h-14 w-14 shrink-0 overflow-hidden rounded-xl">
                              <img
                                class="aspect-square h-full w-full"
                                alt={project.name}
                                src={project.avatar_url}
                              />
                            </span>
                          </.link>

                          <div class="flex flex-col gap-1">
                            <div class="flex items-center gap-1 text-sm text-muted-foreground">
                              <.link
                                navigate={User.url(project)}
                                class="font-semibold hover:underline"
                              >
                                {project.name}
                              </.link>
                              <.icon name="tabler-chevron-right" class="h-4 w-4" />
                              <.link
                                :if={ticket.repository}
                                href={"https://github.com/#{ticket.repository.user.provider_login}/#{ticket.repository.name}/issues/#{ticket.number}"}
                                class="hover:underline"
                              >
                                {ticket.repository.name}#{ticket.number}
                              </.link>
                              <.link
                                :if={!ticket.repository && ticket.url}
                                href={ticket.url}
                                class="hover:underline"
                              >
                                {Algora.Util.path_from_url(ticket.url)}
                              </.link>
                            </div>

                            <.maybe_link href={
                              if ticket.repository,
                                do:
                                  "https://github.com/#{ticket.repository.user.provider_login}/#{ticket.repository.name}/issues/#{ticket.number}",
                                else: ticket.url
                            }>
                              <div class="group flex items-center gap-2">
                                <div class="font-display text-xl font-semibold text-success">
                                  {Money.to_string!(transaction.net_amount)}
                                </div>
                                <div class="line-clamp-1 text-foreground group-hover:underline">
                                  {ticket.title}
                                </div>
                              </div>
                            </.maybe_link>
                            <div :if={ticket.repository && ticket.repository.tech_stack}>
                              <%= for tech <- ticket.repository.tech_stack do %>
                                <.badge>{tech}</.badge>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
            <div
              :if={@has_more_transactions}
              class="flex justify-center mt-4"
              data-load-more-indicator
            >
              <div class="animate-pulse text-muted-foreground">
                <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
              </div>
            </div>
          <% end %>
        </div>
        <!-- Reviews Column -->
        <div class="space-y-4">
          <div class="grid grid-cols-1 gap-4">
            <%= if Enum.empty?(@contributions) do %>
              <h2 class="text-lg font-semibold">Completed Contracts</h2>
              <%= if Enum.empty?(@reviews) do %>
                <.card class="text-center">
                  <.card_header>
                    <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                      <.icon name="tabler-contract" class="h-8 w-8 text-muted-foreground" />
                    </div>
                    <.card_title>No completed contracts yet</.card_title>
                    <.card_description>
                      Contracts will appear here once completed
                    </.card_description>
                  </.card_header>
                </.card>
              <% else %>
                <%= for review <- @reviews do %>
                  <div class="w-full rounded-lg border border-border bg-card p-4 text-sm">
                    <div class="mb-2 flex items-center gap-1">
                      <%= for i <- 1..Review.max_rating() do %>
                        <.icon
                          name="tabler-star-filled"
                          class={"#{if i <= review.rating, do: "text-foreground", else: "text-muted-foreground/25"} h-4 w-4"}
                        />
                      <% end %>
                    </div>
                    <p class="mb-2 text-sm">{review.content}</p>
                    <div class="flex items-center gap-3">
                      <.avatar class="h-8 w-8">
                        <.avatar_image src={review.reviewer.avatar_url} alt={review.reviewer.name} />
                        <.avatar_fallback>
                          {Algora.Util.initials(review.reviewer.name)}
                        </.avatar_fallback>
                      </.avatar>
                      <div class="flex flex-col">
                        <p class="text-sm font-medium">{review.reviewer.name}</p>
                        <p class="text-xs text-muted-foreground">
                          {review.organization.name}
                        </p>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>
            <% else %>
              <h2 class="text-lg font-semibold">Top Contributions</h2>
              <%= for {owner, contributions} <- aggregate_contributions(@contributions) do %>
                <.link
                  href={"https://github.com/#{owner.provider_login}/#{List.first(contributions).repository.name}/pulls?q=author%3A#{@user.provider_login}+is%3Amerged+"}
                  target="_blank"
                  rel="noopener"
                  class="flex items-center gap-3 rounded-xl pr-2 bg-card/50 border border-border/50 hover:border-border transition-all group"
                >
                  <img
                    src={owner.avatar_url}
                    class="h-12 w-12 rounded-xl rounded-r-none  transition-all"
                    alt={owner.name}
                  />
                  <div class="w-full flex flex-col text-xs font-medium gap-0.5">
                    <span class="flex items-start justify-between gap-5">
                      <span class="font-display">
                        {if owner.type == :organization do
                          owner.name
                        else
                          List.first(contributions).repository.name
                        end}
                      </span>
                      <%= if tech = List.first(List.first(contributions).repository.tech_stack) do %>
                        <.tech_badge
                          variant="ghost"
                          class="saturate-0 text-[11px] group-hover:saturate-100 transition-all"
                          tech={tech}
                        />
                      <% end %>
                    </span>
                    <div class="flex items-center gap-2 font-semibold">
                      <span class="flex items-center text-amber-300 text-xs">
                        <.icon name="tabler-star-filled" class="h-4 w-4 mr-1" />
                        {Algora.Util.format_number_compact(
                          max(owner.stargazers_count, total_stars(contributions))
                        )}
                      </span>
                      <span class="flex items-center text-purple-400 text-xs">
                        <.icon name="tabler-git-pull-request" class="h-4 w-4 mr-1" />
                        {Algora.Util.format_number_compact(total_contributions(contributions))}
                      </span>
                    </div>
                  </div>
                </.link>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    {:noreply, assign_more_transactions(socket)}
  end

  defp assign_more_transactions(socket) do
    %{transactions: rows, user: user} = socket.assigns

    last_transaction = List.last(rows).transaction

    more_transactions =
      Payments.list_received_transactions(
        user.id,
        limit: page_size(),
        before: %{
          succeeded_at: last_transaction.succeeded_at,
          id: last_transaction.id
        }
      )

    socket
    |> assign(:transactions, rows ++ to_transaction_rows(more_transactions))
    |> assign(:has_more_transactions, length(more_transactions) >= page_size())
  end

  defp page_size, do: 10

  defp to_transaction_rows(transactions) do
    Enum.map(transactions, fn tx ->
      Map.put(
        tx,
        :project,
        case tx.ticket.repository do
          nil -> tx.sender
          repo -> repo.user
        end
      )
    end)
  end

  defp aggregate_contributions(contributions) do
    groups = Enum.group_by(contributions, fn c -> c.repository.user end)

    contributions
    |> Enum.map(fn c -> {c.repository.user, groups[c.repository.user]} end)
    |> Enum.uniq_by(fn {owner, _} -> owner.id end)
  end

  defp total_stars(contributions) do
    contributions
    |> Enum.map(& &1.repository.stargazers_count)
    |> Enum.sum()
  end

  defp total_contributions(contributions) do
    contributions
    |> Enum.map(& &1.contribution_count)
    |> Enum.sum()
  end
end
