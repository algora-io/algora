defmodule Algora.Activities.DiscordViews do
  @moduledoc false
  alias Algora.Repo

  def render(%{type: type} = activity) when is_binary(type) do
    render(%{activity | type: String.to_existing_atom(type)})
  end

  def render(%{type: :bounty_posted, assoc: bounty}) do
    bounty = Repo.preload(bounty, [:owner, :creator, ticket: [repository: :user]])

    %{
      embeds: [
        %{
          color: 0x6366F1,
          title: "#{bounty.amount} bounty!",
          author: %{
            name: bounty.ticket.repository.user.provider_login,
            icon_url: bounty.ticket.repository.user.avatar_url,
            url:
              "https://github.com/#{bounty.ticket.repository.user.provider_login}/#{bounty.ticket.repository.name}/issues/#{bounty.ticket.number}"
          },
          footer: %{
            text: bounty.creator.name,
            icon_url: bounty.creator.avatar_url
          },
          thumbnail: %{url: bounty.owner.avatar_url},
          fields: [
            %{
              name: "Sponsor",
              value: bounty.owner.name,
              inline: false
            },
            %{
              name: "Ticket",
              value: "#{bounty.ticket.repository.name}##{bounty.ticket.number}: #{bounty.ticket.title}",
              inline: false
            }
          ],
          url:
            "https://github.com/#{bounty.ticket.repository.user.provider_login}/#{bounty.ticket.repository.name}/issues/#{bounty.ticket.number}",
          timestamp: bounty.inserted_at
        }
      ]
    }
  end

  def render(%{type: :transaction_succeeded, assoc: tx}) do
    tx = Repo.preload(tx, [:user, linked_transaction: [:user]])

    %{
      embeds: [
        %{
          color: 0x6366F1,
          title: "#{tx.net_amount} paid!",
          author: %{
            name: tx.linked_transaction.user.name,
            icon_url: tx.linked_transaction.user.avatar_url,
            url: "#{AlgoraWeb.Endpoint.url()}/org/#{tx.linked_transaction.user.handle}"
          },
          footer: %{
            text: tx.user.name,
            icon_url: tx.user.avatar_url
          },
          thumbnail: %{url: tx.user.avatar_url},
          fields: [
            %{
              name: "Sender",
              value: tx.linked_transaction.user.name,
              inline: false
            },
            %{
              name: "Recipient",
              value: tx.user.name,
              inline: false
            }
          ],
          url: "#{AlgoraWeb.Endpoint.url()}/org/#{tx.linked_transaction.user.handle}",
          timestamp: tx.succeeded_at
        }
      ]
    }
  end

  def render(_activity), do: nil
end
