defmodule AlgoraWeb.API.BountyJSON do
  alias Algora.Bounties.Bounty

  @doc """
  Renders a list of bounties.
  """
  def index(%{bounties: bounties}) do
    %{
      data: [
        %{
          result: %{
            data: %{
              json: %{
                # TODO: Implement pagination
                next_cursor: nil,
                items: for(bounty <- bounties, do: data(bounty))
              }
            }
          }
        }
      ]
    }
  end

  @doc """
  Renders a single bounty.
  """
  def show(%{bounty: bounty}) do
    %{
      data: [
        %{
          result: %{
            data: %{
              json: %{
                next_cursor: nil,
                items: [data(bounty)]
              }
            }
          }
        }
      ]
    }
  end

  defp data(%Bounty{} = bounty) do
    %{
      id: bounty.id,
      # TODO: Implement point rewards
      point_reward: nil,
      reward: %{
        amount: bounty.amount.amount,
        currency: bounty.amount.currency
      },
      reward_formatted: "#{bounty.amount.amount} #{bounty.amount.currency}",
      # TODO: Implement reward tiers
      reward_tiers: [],
      tech: bounty.ticket.tech || [],
      status: bounty.status,
      # TODO: Determine if bounty is external
      is_external: false,
      org: org_data(bounty.owner),
      task: task_data(bounty.ticket),
      type: "standard",
      kind: "dev",
      reward_type: "cash",
      visibility: bounty.visibility,
      # TODO: Implement bids
      bids: [],
      autopay_disabled: bounty.autopay_disabled,
      timeouts_disabled: true,
      manual_assignments: false,
      created_at: bounty.inserted_at,
      updated_at: bounty.updated_at
    }
  end

  defp data(%{} = bounty) do
    %{
      id: bounty.id,
      point_reward: nil,
      reward: %{
        amount: bounty.amount.amount,
        currency: bounty.amount.currency
      },
      reward_formatted: "#{bounty.amount.amount} #{bounty.amount.currency}",
      reward_tiers: [],
      tech: bounty.ticket.tech || [],
      status: bounty.status,
      is_external: false,
      org: org_data(bounty.owner),
      task: task_data(bounty.ticket),
      type: "standard",
      kind: "dev",
      reward_type: "cash",
      visibility: Map.get(bounty, :visibility, :public),
      bids: [],
      autopay_disabled: Map.get(bounty, :autopay_disabled, false),
      timeouts_disabled: true,
      manual_assignments: false,
      created_at: bounty.inserted_at,
      updated_at: Map.get(bounty, :updated_at, bounty.inserted_at)
    }
  end

  defp task_data(nil), do: nil

  defp task_data(ticket) do
    %{
      id: ticket.id,
      # TODO: Make this dynamic based on ticket provider
      forge: "github",
      # TODO: Extract from ticket URL
      repo_owner: "TODO",
      # TODO: Extract from ticket URL
      repo_name: "TODO",
      number: ticket.number,
      source: %{
        # TODO: Make this dynamic based on ticket provider
        type: "github",
        data: %{
          id: ticket.id,
          html_url: ticket.url,
          # TODO: Add title to ticket schema
          title: "TODO",
          # TODO: Add body to ticket schema
          body: "TODO",
          user: %{
            # TODO: Add creator info to ticket schema
            id: 0,
            login: "TODO",
            avatar_url: "TODO",
            html_url: "TODO",
            name: "TODO",
            company: "TODO",
            location: "TODO",
            twitter_username: "TODO"
          }
        }
      },
      # TODO: Map ticket status
      status: "open",
      # TODO: Add title to ticket schema
      title: "TODO",
      url: ticket.url,
      # TODO: Add body to ticket schema
      body: "TODO",
      # TODO: Make this dynamic
      type: "issue",
      hash: ticket.hash || "",
      tech: ticket.tech || []
    }
  end

  defp org_data(nil), do: nil

  defp org_data(org) do
    %{
      id: org.id,
      created_at: org.inserted_at,
      handle: org.handle,
      name: org.name,
      display_name: org.display_name || org.name,
      description: org.bio || "",
      avatar_url: org.avatar_url,
      website_url: org.website_url || "",
      twitter_url: org.twitter_url || "",
      youtube_url: org.youtube_url || "",
      discord_url: org.discord_url || "",
      slack_url: org.slack_url,
      stargazers_count: org.stargazers_count || 0,
      tech: org.tech_stack || [],
      # TODO: Add to org schema
      accepts_sponsorships: false,
      members: members_data(org),
      # TODO: Add to org schema
      enabled_expert_recs: false,
      # TODO: Add to org schema
      enabled_private_bounties: false,
      days_until_timeout: nil,
      github_handle: org.provider_login
    }
  end

  defp members_data(org) do
    # TODO: Implement actual member fetching
    []
  end

  defp user_data(nil), do: nil

  defp user_data(user) do
    %{
      id: user.id,
      handle: user.handle,
      image: user.avatar_url,
      name: user.name,
      github_handle: user.provider_login,
      youtube_handle: nil,
      twitch_handle: nil,
      # TODO: Implement org fetching for user
      orgs: []
    }
  end
end
