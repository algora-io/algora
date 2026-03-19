defmodule Algora.Bounties do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.BotTemplates
  alias Algora.BotTemplates.BotTemplate
  alias Algora.Bounties.Attempt
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Jobs
  alias Algora.Bounties.LineItem
  alias Algora.Bounties.Tip
  alias Algora.Organizations.Member
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.PSP
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Ticket

  require Logger

  def base_query, do: Bounty

  @type criterion ::
          {:id, String.t()}
          | {:limit, non_neg_integer() | :infinity}
          | {:ticket_id, String.t()}
          | {:owner_id, String.t()}
          | {:owner_handles, [String.t()]}
          | {:status, :open | :paid}
          | {:tech_stack, [String.t()]}
          | {:before, %{inserted_at: DateTime.t(), id: String.t()}}
          | {:amount_gt, Money.t()}
          | {:bounty_range, {Money.t(), Money.t()}}
          | {:current_user, User.t()}

  def broadcast do
    Phoenix.PubSub.broadcast(Algora.PubSub, "bounties:all", :bounties_updated)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "bounties:all")
  end

  def filter_by_bounty_range(query, {min_amount, max_amount}) do
    from b in query,
      where: b.amount >= ^min_amount and b.amount <= ^max_amount
  end

  @spec do_create_bounty(%{
          creator: User.t(),
          owner: User.t(),
          amount: Money.t(),
          ticket: Ticket.t(),
          visibility: Bounty.visibility(),
          shar