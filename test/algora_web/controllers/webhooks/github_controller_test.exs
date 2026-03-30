# Test for GitHub webhook bounty sync fix
defmodule AlgoraWeb.Webhooks.GithubControllerTest do
  use AlgoraWeb.ConnCase, async: true
  import Algora.Factory

  alias Algora.Bounties.Bounty
  alias Algora.Repo
  alias Algora.Workspace.Ticket

  describe "handle_ticket_state_change/1" do
    test "marks bounties as cancelled when GitHub issue is closed" do
      # Create a ticket and associated bounty
      ticket = insert(:ticket, state: :open)
      bounty = insert(:bounty, ticket: ticket, status: :open)

      # Simulate GitHub issue closed webhook
      webhook = %{
        payload: %{
          "repository" => %{
            "owner" => %{"login" => ticket.repository.user.provider_login},
            "name" => ticket.repository.name
          }
        },
        event_action: "issues.closed"
      }

      github_ticket = %{
        "number" => ticket.number,
        "state" => "closed",
        "closed_at" => "2026-03-30T22:00:00Z",
        "merged_at" => nil
      }

      # Mock the GitHub ticket response
      expect(MockGithub, :get_github_ticket, fn _webhook -> github_ticket end)

      # Process the webhook
      assert :ok = AlgoraWeb.Webhooks.GithubController.handle_ticket_state_change(webhook)

      # Verify ticket state is updated
      updated_ticket = Repo.get(Ticket, ticket.id)
      assert updated_ticket.state == :closed

      # Verify bounty status is synced
      updated_bounty = Repo.get(Bounty, bounty.id)
      assert updated_bounty.status == :cancelled
    end

    test "reopens bounties when GitHub issue is reopened" do
      # Create a closed ticket with cancelled bounty
      ticket = insert(:ticket, state: :closed)
      bounty = insert(:bounty, ticket: ticket, status: :cancelled)

      # Simulate GitHub issue reopened webhook
      webhook = %{
        payload: %{
          "repository" => %{
            "owner" => %{"login" => ticket.repository.user.provider_login},
            "name" => ticket.repository.name
          }
        },
        event_action: "issues.reopened"
      }

      github_ticket = %{
        "number" => ticket.number,
        "state" => "open",
        "closed_at" => nil,
        "merged_at" => nil
      }

      # Mock the GitHub ticket response
      expect(MockGithub, :get_github_ticket, fn _webhook -> github_ticket end)

      # Process the webhook
      assert :ok = AlgoraWeb.Webhooks.GithubController.handle_ticket_state_change(webhook)

      # Verify ticket state is updated
      updated_ticket = Repo.get(Ticket, ticket.id)
      assert updated_ticket.state == :open

      # Verify bounty status is synced
      updated_bounty = Repo.get(Bounty, bounty.id)
      assert updated_bounty.status == :open
    end
  end
end