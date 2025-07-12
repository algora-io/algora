defmodule AlgoraWeb.Org.BountiesLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use Ecto.Schema

  import Ecto.Changeset

  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Github
  alias Algora.Payments
  alias Algora.Repo
  alias Algora.Types.USD
  alias Algora.Workspace

  embedded_schema do
    field :amount, USD
  end

  def edit_amount_changeset(attrs \\ %{}) do
    %__MODULE__{}
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
    |> Algora.Validations.validate_money_positive(:amount)
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:show_edit_modal, false)
     |> assign(:editing_bounty, nil)
     |> assign(:edit_form, to_form(edit_amount_changeset()))}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto p-6" id="bounties-container" phx-hook="InfiniteScroll">
      <div class="mb-6">
        <div class="flex flex-wrap items-start justify-between gap-4 lg:flex-nowrap">
          <div>
            <h2 class="text-2xl font-bold dark:text-white">Bounties</h2>
            <p class="text-sm dark:text-gray-300">
              Create new bounties by commenting
              <code class="mx-1 inline-block rounded bg-emerald-950/75 px-1 py-0.5 font-mono text-sm text-emerald-400 ring-1 ring-emerald-400/25">
                /bounty $1000
              </code>
              on GitHub issues.
            </p>
          </div>
          <div class="pb-4 md:pb-0">
            <!-- Tab buttons for Open and Completed bounties -->
            <div dir="ltr" data-orientation="horizontal">
              <div
                role="tablist"
                aria-orientation="horizontal"
                class="-ml-1 grid h-full w-full grid-cols-2 items-center justify-center gap-1 rounded-md p-1 bg-muted text-card-foreground"
                tabindex="0"
                data-orientation="horizontal"
                style="outline: none;"
              >
                <.button
                  type="button"
                  role="tab"
                  aria-selected={@current_status == :open}
                  variant={if @current_status == :open, do: "default", else: "ghost"}
                  phx-click="change-tab"
                  phx-value-tab="open"
                >
                  <div class="relative flex items-center gap-2.5 text-sm md:text-base">
                    <div class="truncate">Open</div>
                    <span class={"min-w-[1ch] font-mono #{if @current_status == :open, do: "text-emerald-200", else: "text-gray-400 group-hover:text-emerald-200"}"}>
                      {@stats.open_bounties_count}
                    </span>
                  </div>
                </.button>

                <.button
                  type="button"
                  role="tab"
                  aria-selected={@current_status == :paid}
                  variant={if @current_status == :paid, do: "default", else: "ghost"}
                  phx-click="change-tab"
                  phx-value-tab="completed"
                >
                  <div class="relative flex items-center gap-2.5 text-sm md:text-base">
                    <div class="truncate">Completed</div>
                    <span class={"min-w-[1ch] font-mono #{if @current_status == :paid, do: "text-emerald-200", else: "text-gray-400 group-hover:text-emerald-200"}"}>
                      {@stats.rewarded_bounties_count + @stats.rewarded_tips_count}
                    </span>
                  </div>
                </.button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div :if={@current_status == :open} class="overflow-hidden rounded-xl border border-white/15">
        <div class="scrollbar-thin w-full overflow-auto">
          <table class="w-full caption-bottom text-sm">
            <tbody class="[&_tr:last-child]:border-0">
              <%= for %{bounty: bounty, claim_groups: claim_groups} <- @bounty_rows do %>
                <tr
                  class="bg-white/[2%] from-white/[2%] via-white/[2%] to-white/[2%] border-b border-white/15 bg-gradient-to-br transition-colors data-[state=selected]:bg-gray-100 hover:bg-gray-100/50 dark:data-[state=selected]:bg-gray-800 dark:hover:bg-white/[2%]"
                  data-state="false"
                >
                  <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                    <div class="min-w-[250px]">
                      <div class="group relative flex h-full flex-col">
                        <div class="relative h-full pl-2">
                          <div class="flex items-start justify-between">
                            <div class="cursor-pointer font-mono text-2xl">
                              <div class="font-extrabold text-emerald-300 hover:text-emerald-200">
                                {Money.to_string!(bounty.amount)}
                              </div>
                            </div>
                          </div>
                          <.link
                            rel="noopener"
                            class="group/issue inline-flex flex-col"
                            href={Bounty.url(bounty)}
                          >
                            <div class="flex items-center gap-4">
                              <div class="truncate">
                                <p class="truncate text-sm font-medium text-gray-300 group-hover/issue:text-gray-200 group-hover/issue:underline">
                                  {Bounty.path(bounty)}
                                </p>
                              </div>
                            </div>
                            <p class="line-clamp-2 break-words text-base font-medium leading-tight text-gray-100 group-hover/issue:text-white group-hover/issue:underline">
                              {bounty.ticket.title}
                            </p>
                          </.link>
                          <p class="flex items-center gap-1.5 text-xs text-gray-400">
                            {Algora.Util.time_ago(bounty.inserted_at)}
                          </p>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                    <%= if map_size(claim_groups) > 0 do %>
                      <div class="group flex cursor-pointer flex-col items-center gap-1">
                        <div class="flex cursor-pointer justify-center -space-x-3">
                          <%= for {_group_id, claims} <- claim_groups do %>
                            <div class="relative h-10 w-10 flex-shrink-0 rounded-full ring-4 ring-gray-800 group-hover:brightness-110">
                              <img
                                alt={User.handle(hd(claims).user)}
                                loading="lazy"
                                decoding="async"
                                class="rounded-full"
                                src={hd(claims).user.avatar_url}
                                style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                              />
                            </div>
                          <% end %>
                        </div>
                        <div class="flex items-center gap-0.5">
                          <div class="whitespace-nowrap text-sm font-medium text-gray-300 group-hover:text-gray-100">
                            {map_size(claim_groups)} {ngettext(
                              "claim",
                              "claims",
                              map_size(claim_groups)
                            )}
                          </div>
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="-mr-4 h-4 w-4 rotate-90 text-gray-400 group-hover:text-gray-300"
                          >
                            <path d="M9 6l6 6l-6 6"></path>
                          </svg>
                        </div>
                      </div>
                    <% end %>
                  </td>
                  <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                    <div class="flex items-center gap-2">
                      <.button
                        phx-click="edit-bounty-amount"
                        phx-value-id={bounty.id}
                        variant="secondary"
                        size="sm"
                      >
                        Edit Amount
                      </.button>
                      <.button
                        phx-click="delete-bounty"
                        phx-value-id={bounty.id}
                        variant="destructive"
                        size="sm"
                      >
                        Delete
                      </.button>
                    </div>
                  </td>
                </tr>
                <%= for {_group_id, claims} <- claim_groups do %>
                  <tr
                    class="border-b border-white/15 bg-gray-950/50 transition-colors data-[state=selected]:bg-gray-100 hover:bg-gray-100/50 dark:data-[state=selected]:bg-gray-800 dark:hover:bg-gray-950/50"
                    data-state="false"
                  >
                    <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle w-full">
                      <div class="min-w-[250px]">
                        <div class="flex items-center gap-3">
                          <div class="flex -space-x-3">
                            <%= for claim <- claims do %>
                              <div class="relative h-10 w-10 flex-shrink-0 rounded-full ring-4 ring-background">
                                <img
                                  alt={User.handle(claim.user)}
                                  loading="lazy"
                                  decoding="async"
                                  class="rounded-full"
                                  src={claim.user.avatar_url}
                                  style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                                />
                              </div>
                            <% end %>
                          </div>
                          <div>
                            <div class="text-sm font-medium text-gray-200">
                              {claims
                              |> Enum.map(fn c -> User.handle(c.user) end)
                              |> Algora.Util.format_name_list()}
                            </div>
                            <div class="text-xs text-gray-400">
                              {Algora.Util.time_ago(hd(claims).inserted_at)}
                            </div>
                          </div>
                        </div>
                      </div>
                    </td>
                    <td class="[&:has([role=checkbox])]:pr-0 p-4 align-middle">
                      <div class="min-w-[180px]">
                        <div class="flex items-center justify-end gap-4">
                          <.button
                            :if={hd(claims).source}
                            href={hd(claims).source.url}
                            variant="secondary"
                          >
                            View
                          </.button>
                          <.button href={~p"/claims/#{hd(claims).group_id}"}>
                            Reward
                          </.button>
                        </div>
                      </div>
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>
        </div>
        <div :if={@has_more_bounties} class="flex justify-center mt-4" data-load-more-indicator>
          <div class="animate-pulse text-gray-400">
            <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
          </div>
        </div>
      </div>
      <div :if={@current_status == :paid} class="relative">
        <%= for %{transaction: transaction, recipient: recipient, ticket: ticket} <- @transaction_rows do %>
          <div class="mb-4 rounded-lg border border-border bg-card p-4">
            <div class="flex gap-4">
              <div class="flex-1">
                <div class="mb-2 font-mono text-2xl font-extrabold text-success">
                  {Money.to_string!(transaction.net_amount)}
                </div>
                <div :if={ticket.repository} class="mb-1 text-sm text-muted-foreground">
                  {ticket.repository.user.provider_login}/{ticket.repository.name}#{ticket.number}
                </div>
                <div class="font-medium">
                  {ticket.title}
                </div>
                <div class="mt-1 text-xs text-muted-foreground">
                  {Algora.Util.time_ago(transaction.succeeded_at)}
                </div>
              </div>

              <div class="flex w-32 flex-col items-center border-l border-border pl-4">
                <h3 class="mb-3 text-xs font-medium uppercase text-muted-foreground">
                  Awarded to
                </h3>
                <img
                  src={recipient.avatar_url}
                  class="mb-2 h-16 w-16 rounded-full"
                  alt={recipient.name}
                />
                <div class="text-center text-sm font-medium">
                  {recipient.name}
                  <div>
                    {Algora.Misc.CountryEmojis.get(recipient.country)}
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>
        <div :if={@has_more_transactions} class="flex justify-center mt-4" data-load-more-indicator>
          <div class="animate-pulse text-gray-400">
            <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
          </div>
        </div>
      </div>
    </div>

    <!-- Edit Amount Drawer -->
    <.drawer show={@show_edit_modal} direction="right" on_cancel="cancel-edit">
      <.drawer_header>
        <.drawer_title>Edit Bounty Amount</.drawer_title>
        <.drawer_description>
          Update the bounty amount for this issue
        </.drawer_description>
      </.drawer_header>
      <.drawer_content>
        <.form
          for={@edit_form}
          as="edit_amount"
          phx-submit="save-bounty-amount"
          phx-change="validate-amount"
          class="space-y-4"
        >
          <.input
            label="New Amount"
            icon="tabler-currency-dollar"
            field={@edit_form[:amount]}
            placeholder="e.g., 1000"
          />
          <div class="flex gap-3 justify-end">
            <.button type="button" variant="secondary" phx-click="cancel-edit">
              Cancel
            </.button>
            <.button type="submit" variant="default">
              Save
            </.button>
          </div>
        </.form>
      </.drawer_content>
    </.drawer>
    """
  end

  def handle_event("change-tab", %{"tab" => "completed"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/#{socket.assigns.current_org.handle}/bounties?status=completed")}
  end

  def handle_event("change-tab", %{"tab" => "open"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/#{socket.assigns.current_org.handle}/bounties?status=open")}
  end

  def handle_event("load_more", _params, socket) do
    {:noreply,
     case socket.assigns.current_status do
       :open -> assign_more_bounties(socket)
       :paid -> assign_more_transactions(socket)
     end}
  end

  def handle_event("delete-bounty", %{"id" => bounty_id}, socket) do
    cond do
      socket.assigns.current_user_role in [:admin, :mod] ->
        bounty =
          Bounty
          |> Repo.get(bounty_id)
          |> Repo.preload([:owner, [ticket: [repository: :user]]])

        with {:ok, installation} <-
               Workspace.fetch_installation_by(
                 provider: "github",
                 connected_user_id: bounty.ticket.repository.user.id
               ),
             {:ok, token} <- Github.get_installation_token(installation.provider_id),
             {:ok, cr} <-
               Workspace.fetch_command_response(bounty.ticket_id, :bounty),
             {:ok, _} <-
               Github.delete_issue_comment(
                 token,
                 bounty.ticket.repository.user.provider_login,
                 bounty.ticket.repository.name,
                 cr.provider_response_id
               ),
             :ok <-
               Workspace.remove_existing_amount_labels(
                 token,
                 bounty.ticket.repository.user.provider_login,
                 bounty.ticket.repository.name,
                 bounty.ticket.number
               ),
             {:ok, _} <-
               Github.remove_label_from_issue(
                 token,
                 bounty.ticket.repository.user.provider_login,
                 bounty.ticket.repository.name,
                 bounty.ticket.number,
                 "💎 Bounty"),
               
             {:ok, _} <- Workspace.delete_command_response(cr.id),
             {:ok, _bounty} <- Bounties.delete_bounty(bounty) do
          {:noreply,
           socket
           |> put_flash(:info, "Bounty deleted successfully")
           |> assign_bounties()}
        else
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to delete bounty")}
        end

      is_nil(socket.assigns.current_user) ->
        {:noreply,
         redirect(socket,
           to: ~p"/auth/login?#{%{return_to: ~p"/#{socket.assigns.current_org.handle}/bounties"}}"
         )}

      true ->
        {:noreply, put_flash(socket, :error, "You are not authorized to delete bounties")}
    end
  end

  def handle_event("edit-bounty-amount", %{"id" => bounty_id}, socket) do
    cond do
      socket.assigns.current_user_role in [:admin, :mod] ->
        [bounty] = Bounties.list_bounties(id: bounty_id)
        changeset = edit_amount_changeset(%{amount: bounty.amount})

        {:noreply,
         socket
         |> assign(:editing_bounty, bounty)
         |> assign(:edit_form, to_form(changeset))
         |> assign(:show_edit_modal, true)}

      is_nil(socket.assigns.current_user) ->
        {:noreply,
         redirect(socket,
           to: ~p"/auth/login?#{%{return_to: ~p"/#{socket.assigns.current_org.handle}/bounties"}}"
         )}

      true ->
        {:noreply, put_flash(socket, :error, "You are not authorized to edit bounty amounts")}
    end
  end

  def handle_event("validate-amount", params, socket) do
    form_params =
      case params do
        %{"edit_amount" => form_params} -> form_params
        %{"bounties_live" => form_params} -> form_params
        _ -> %{}
      end

    changeset =
      form_params
      |> edit_amount_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :edit_form, to_form(changeset))}
  end

  def handle_event("save-bounty-amount", params, socket) do
    form_params =
      case params do
        %{"edit_amount" => form_params} -> form_params
        %{"bounties_live" => form_params} -> form_params
        _ -> %{}
      end

    changeset = edit_amount_changeset(form_params)

    case apply_action(changeset, :update) do
      {:ok, %{amount: amount}} ->
        bounty =
          Bounty
          |> Repo.get(socket.assigns.editing_bounty.id)
          |> Repo.preload([:owner, [ticket: [repository: :user]]])

        with {:ok, installation} <-
               Workspace.fetch_installation_by(
                 provider: "github",
                 connected_user_id: bounty.ticket.repository.user.id
               ),
             {:ok, bounty} <-
               bounty
               |> Bounty.changeset(%{amount: amount})
               |> Repo.update(),
             {:ok, cr} <-
               Workspace.fetch_command_response(bounty.ticket_id, :bounty),
             {:ok, _job} <-
               Bounties.notify_bounty(
                 %{
                   owner: bounty.owner,
                   bounty: bounty,
                   ticket_ref: %{
                     owner: bounty.ticket.repository.user.provider_login,
                     repo: bounty.ticket.repository.name,
                     number: bounty.ticket.number
                   }
                 },
                 installation_id: installation.provider_id,
                 command_id: cr.provider_command_id,
                 command_source: cr.command_source
               ) do
          {:noreply,
           socket
           |> assign(:show_edit_modal, false)
           |> assign(:editing_bounty, nil)
           |> assign(:edit_form, to_form(edit_amount_changeset()))
           |> put_flash(:info, "Bounty amount updated successfully")
           |> assign_bounties()}
        else
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update bounty amount")}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :edit_form, to_form(changeset))}
    end
  end

  def handle_event("cancel-edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_modal, false)
     |> assign(:editing_bounty, nil)
     |> assign(:edit_form, to_form(edit_amount_changeset()))}
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  def handle_params(params, _uri, socket) do
    current_org = socket.assigns.current_org
    current_status = get_current_status(params)

    stats = Bounties.fetch_stats(org_id: current_org.id, current_user: socket.assigns[:current_user])

    bounties =
      Bounties.list_bounties(
        owner_id: current_org.id,
        limit: page_size(),
        status: :open,
        current_user: socket.assigns[:current_user]
      )

    transactions = Payments.list_hosted_transactions(current_org.id, limit: page_size())

    {:noreply,
     socket
     |> assign(:current_status, current_status)
     |> assign(:bounty_rows, to_bounty_rows(bounties))
     |> assign(:transaction_rows, to_transaction_rows(transactions))
     |> assign(:has_more_bounties, length(bounties) >= page_size())
     |> assign(:has_more_transactions, length(transactions) >= page_size())
     |> assign(:stats, stats)}
  end

  defp to_bounty_rows(bounties) do
    claims_by_ticket =
      bounties
      |> Enum.map(& &1.ticket.id)
      |> Bounties.list_claims()
      |> Enum.group_by(& &1.target_id)
      |> Map.new(fn {ticket_id, claims} ->
        {ticket_id, Enum.group_by(claims, & &1.group_id)}
      end)

    Enum.map(bounties, fn bounty ->
      %{bounty: bounty, claim_groups: Map.get(claims_by_ticket, bounty.ticket.id, %{})}
    end)
  end

  defp to_transaction_rows(transactions), do: transactions

  defp assign_more_bounties(socket) do
    %{bounty_rows: rows, current_org: current_org} = socket.assigns

    last_bounty = List.last(rows).bounty

    cursor = %{
      inserted_at: last_bounty.inserted_at,
      id: last_bounty.id
    }

    more_bounties =
      Bounties.list_bounties(
        owner_id: current_org.id,
        limit: page_size(),
        status: socket.assigns.current_status,
        before: cursor,
        current_user: socket.assigns[:current_user]
      )

    socket
    |> assign(:bounty_rows, rows ++ to_bounty_rows(more_bounties))
    |> assign(:has_more_bounties, length(more_bounties) >= page_size())
  end

  defp assign_more_transactions(socket) do
    %{transaction_rows: rows, current_org: current_org} = socket.assigns

    last_transaction = List.last(rows).transaction

    more_transactions =
      Payments.list_hosted_transactions(
        current_org.id,
        limit: page_size(),
        before: %{
          succeeded_at: last_transaction.succeeded_at,
          id: last_transaction.id
        }
      )

    socket
    |> assign(:transaction_rows, rows ++ to_transaction_rows(more_transactions))
    |> assign(:has_more_transactions, length(more_transactions) >= page_size())
  end

  defp get_current_status(params) do
    case params["status"] do
      "open" -> :open
      "completed" -> :paid
      _ -> :open
    end
  end

  defp page_size, do: 10

  defp assign_bounties(socket) do
    current_org = socket.assigns.current_org

    bounties =
      Bounties.list_bounties(
        owner_id: current_org.id,
        limit: page_size(),
        status: :open,
        current_user: socket.assigns[:current_user]
      )

    assign(socket, :bounty_rows, to_bounty_rows(bounties))
  end
end
