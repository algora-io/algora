defmodule AlgoraWeb.Components.Bounties do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  alias Algora.Accounts.User
  alias Algora.Bounties.Bounty

  def bounties(assigns) do
    ~H"""
    <div class="relative -mx-2 -mt-2 overflow-auto scrollbar-thin">
      <ul class="divide-y divide-border">
        <%= for bounty <- @bounties do %>
          <% activity = bounty_activity(bounty) %>
          <.link href={Bounty.url(bounty)} class="block whitespace-nowrap hover:bg-muted/50">
            <li class="flex items-center py-2 px-3">
              <div class="flex-shrink-0 mr-3">
                <.avatar class="h-8 w-8">
                  <.avatar_image src={bounty.repository.owner.avatar_url || bounty.owner.avatar_url} />
                  <.avatar_fallback>
                    {Algora.Util.initials(User.handle(bounty.repository.owner || bounty.owner))}
                  </.avatar_fallback>
                </.avatar>
              </div>

              <div class="flex-grow min-w-0 mr-4">
                <div class="flex items-center text-sm">
                  <span class="font-semibold mr-1">
                    {bounty.repository.owner.name || bounty.owner.name}
                  </span>
                  <span :if={bounty.ticket.number} class="text-muted-foreground mr-2">
                    #{bounty.ticket.number}
                  </span>
                  <span class="font-display whitespace-nowrap text-sm font-semibold tabular-nums text-success mr-2">
                    {Money.to_string!(bounty.amount)}
                  </span>
                  <span
                    :if={active_bounty?(activity)}
                    class="mr-2 rounded-full bg-success/10 px-2 py-0.5 text-xs font-medium text-success"
                  >
                    Active
                  </span>
                  <span class="text-foreground">{bounty.ticket.title}</span>
                </div>

                <div class="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
                  <span :if={activity.active_attempt_count > 0} class="inline-flex items-center gap-1">
                    <.icon name="tabler-users" class="size-3.5" />
                    {activity.active_attempt_count} active
                  </span>
                  <span :if={activity.pull_request_count > 0} class="inline-flex items-center gap-1">
                    <.icon name="tabler-git-pull-request" class="size-3.5" />
                    {activity.pull_request_count} {pr_label(activity.pull_request_count)}
                  </span>
                  <span :if={activity.last_activity_at} class="inline-flex items-center gap-1">
                    <.icon name="tabler-clock" class="size-3.5" />
                    {Algora.Util.relative_time(activity.last_activity_at)}
                  </span>
                </div>
              </div>
            </li>
          </.link>
        <% end %>
      </ul>
    </div>
    """
  end

  defp bounty_activity(%{activity: activity}) when is_map(activity) do
    %{
      active_attempt_count: Map.get(activity, :active_attempt_count, 0),
      pull_request_count: Map.get(activity, :pull_request_count, 0),
      last_activity_at: Map.get(activity, :last_activity_at)
    }
  end

  defp bounty_activity(bounty) do
    %{
      active_attempt_count: 0,
      pull_request_count: 0,
      last_activity_at: Map.get(bounty, :inserted_at)
    }
  end

  defp active_bounty?(%{active_attempt_count: attempts, pull_request_count: prs}) do
    attempts > 0 or prs > 0
  end

  defp pr_label(1), do: "PR"
  defp pr_label(_count), do: "PRs"
end
