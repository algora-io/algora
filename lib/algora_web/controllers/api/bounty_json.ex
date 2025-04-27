defmodule AlgoraWeb.API.BountyJSON do
  alias Algora.Bounties.Bounty

  def index(%{bounties: bounties}) do
    [
      %{
        result: %{
          data: %{
            json: %{
              next_cursor: nil,
              items: for(bounty <- bounties, do: data(bounty))
            }
          }
        }
      }
    ]
  end

  defp data(%{} = bounty) do
    %{
      id: bounty.id,
      point_reward: nil,
      reward: %{
        amount: Algora.MoneyUtils.to_minor_units(bounty.amount),
        currency: bounty.amount.currency
      },
      reward_formatted: Money.to_string!(bounty.amount, no_fraction_if_integer: true),
      reward_tiers: [],
      tech: bounty.owner.tech_stack,
      status: bounty.status,
      is_external: false,
      org: org_data(bounty.owner),
      task: task_data(bounty),
      type: "standard",
      kind: "dev",
      reward_type: "cash",
      visibility: "public",
      bids: [],
      autopay_disabled: false,
      timeouts_disabled: false,
      manual_assignments: false,
      created_at: bounty.inserted_at,
      updated_at: bounty.inserted_at
    }
  end

  defp task_data(bounty) do
    %{
      id: bounty.ticket.id,
      forge: "github",
      repo_owner: bounty.repository.owner.provider_login,
      repo_name: bounty.repository.name,
      number: bounty.ticket.number,
      source: %{
        type: "github",
        data: %{
          id: bounty.ticket.id,
          html_url: bounty.ticket.url,
          title: bounty.ticket.title,
          body: bounty.ticket.description,
          user: %{
            id: 0,
            login: "",
            avatar_url: "",
            html_url: "",
            name: "",
            company: "",
            location: "",
            twitter_username: ""
          }
        }
      },
      status: "open",
      title: bounty.ticket.title,
      url: bounty.ticket.url,
      body: bounty.ticket.description,
      type: "issue",
      hash: Bounty.path(bounty),
      tech: []
    }
  end

  defp org_data(nil), do: nil

  defp org_data(org) do
    %{
      id: org.id,
      created_at: org.inserted_at,
      handle: org.handle,
      name: org.name,
      display_name: org.name,
      description: "",
      avatar_url: org.avatar_url,
      website_url: "",
      twitter_url: "",
      youtube_url: "",
      discord_url: "",
      slack_url: "",
      stargazers_count: 0,
      tech: org.tech_stack,
      accepts_sponsorships: false,
      members: members_data(org),
      enabled_expert_recs: false,
      enabled_private_bounties: false,
      days_until_timeout: nil,
      github_handle: org.provider_login
    }
  end

  defp members_data(_org) do
    []
  end
end
