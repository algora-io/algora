defmodule Algora.Activities do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Activities.Activity
  alias Algora.Repo
  alias Ecto.Multi

  @tables [
    :identity_activities,
    :user_activities,
    :attempt_activities,
    :bonus_activities,
    :bounty_activities,
    :claim_activities,
    :tip_activities,
    :message_activities,
    :thread_activities,
    :contract_activities,
    :timesheet_activities,
    :application_activities,
    :job_activities,
    :account_activities,
    :customer_activities,
    :payment_method_activities,
    :platform_transaction_activities,
    :transaction_activities,
    :project_activities,
    :review_activities,
    :installation_activities,
    :repository_activities,
    :ticket_activities
  ]

  @user_attributes [
    :identities,
    :owned_bounties,
    :created_bounties,
    # :attempts,
    :claims,
    # :projects,
    :repositories,
    :owned_installations,
    :connected_installations,
    :client_contracts,
    :client_contracts,
    :contractor_contracts
  ]

  def tables, do: @tables
  def user_attributes, do: @user_attributes

  def base_query do
    [head | tail] = @tables
    query = head |> to_string() |> base_query()

    Enum.reduce(tail, query, fn table_path, acc ->
      new_query = base_query(table_path)
      union_all(new_query, ^acc)
    end)
  end

  def base_query(table_name) when is_atom(table_name) do
    table_name |> to_string() |> base_query()
  end

  def base_query(table_name) when is_binary(table_name) do
    assoc_name = schema_from_table(table_name)
    base = from(e in {table_name, Activity})

    from(u in subquery(base),
      select_merge: %{
        id: u.id,
        type: u.type,
        assoc_id: u.assoc_id,
        assoc_name: ^table_name
      }
    )
  end

  def base_query_for_user(user_id) do
    [head | tail] = @user_attributes
    first_query = base_query_for_user(user_id, head)

    Enum.reduce(tail, first_query, fn relation_name, acc ->
      new_query = base_query_for_user(user_id, relation_name)
      union_all(new_query, ^acc)
    end)
  end

  def base_query_for_user(user_id, relation_name) do
    table_name = table_from_user_relation(relation_name)
    assoc_name = schema_from_table(table_name)

    base =
      from u in User,
        where: u.id == ^user_id,
        join: c in assoc(u, ^relation_name),
        join: a in assoc(c, :activities),
        select: %{
          id: a.id,
          type: a.type,
          assoc_id: a.assoc_id,
          assoc_name: ^table_name,
          inserted_at: a.inserted_at
        }
  end

  def all(table_name) when is_binary(table_name) do
    table_name
    |> base_query()
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def all(target) when is_map(target) do
    target
    |> Ecto.assoc(:activities)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def all do
    base_query()
    |> order_by(fragment("inserted_at DESC"))
    |> limit(40)
    |> all_with_assoc()
  end

  def all_for_user(user_id) do
    user_id
    |> base_query_for_user()
    |> order_by(fragment("inserted_at DESC"))
    |> limit(40)
    |> all_with_assoc()
  end

  def insert(target, activity) do
    target
    |> Activity.build_activity(activity)
    |> Algora.Repo.insert()
  end

  def dataloader() do
    Dataloader.add_source(
      Dataloader.new,
      :db,
      Dataloader.Ecto.new(Algora.Repo)
    )
  end

  def all_with_assoc(query) do
    activities = Repo.all(query)
    loader =
      activities
      |> Enum.reduce(dataloader(), fn(activity, loader) ->
        schema = schema_from_table(activity.assoc_name)
        Dataloader.load(loader, :db, schema, activity.assoc_id)
      end)
      |> Dataloader.run()

    Enum.map(activities, fn(activity) ->
      schema = schema_from_table(activity.assoc_name)
      assoc = Dataloader.get(loader, :db, schema, activity.assoc_id)
      Map.put(activity, :assoc, assoc)
    end)
  end

  def schema_from_table("identity_activities"), do: Algora.Accounts.Identity
  def schema_from_table("user_activities"), do: Algora.Accounts.User
  def schema_from_table("attempt_activities"), do: Algora.Bounties.Attempt
  def schema_from_table("bonus_activities"), do: Algora.Bounties.Bonus
  def schema_from_table("bounty_activities"), do: Algora.Bounties.Bounty
  def schema_from_table("claim_activities"), do: Algora.Bounties.Claim
  def schema_from_table("tip_activities"), do: Algora.Bounties.Tip
  def schema_from_table("message_activities"), do: Algora.Chat.Message
  def schema_from_table("thread_activities"), do: Algora.Chat.Thread
  def schema_from_table("contract_activities"), do: Algora.Contracts.Contract
  def schema_from_table("timesheet_activities"), do: Algora.Contracts.Timesheet
  def schema_from_table("application_activities"), do: Algora.Jobs.Application
  def schema_from_table("job_activities"), do: Algora.Jobs.Job
  def schema_from_table("account_activities"), do: Algora.Payments.Account
  def schema_from_table("customer_activities"), do: Algora.Payments.Customer
  def schema_from_table("payment_method_activities"), do: Algora.Payments.PaymentMethod
  def schema_from_table("platform_transaction_activities"), do: Algora.Payments.PlatformTransaction
  def schema_from_table("transaction_activities"), do: Algora.Payments.Transaction
  def schema_from_table("project_activities"), do: Algora.Projects.Project
  def schema_from_table("review_activities"), do: Algora.Reviews.Project
  def schema_from_table("installation_activities"), do: Algora.Workplace.Installation
  def schema_from_table("ticket_activities"), do: Algora.Workspace.Ticket
  def schema_from_table("repository_activities"), do: Algora.Workspace.Repository

  def table_from_user_relation(:attempts), do: "attempt_activities"
  def table_from_user_relation(:claims), do: "claim_activities"
  def table_from_user_relation(:client_contracts), do: "contract_activities"
  def table_from_user_relation(:connected_installations), do: "installation_activities"
  def table_from_user_relation(:contractor_contracts), do: "contract_activities"
  def table_from_user_relation(:created_bounties), do: "bounty_activities"
  def table_from_user_relation(:owned_bounties), do: "bounty_activities"
  def table_from_user_relation(:identities), do: "identity_activities"
  def table_from_user_relation(:owned_installations), do: "installation_activities"
  def table_from_user_relation(:projects), do: "project_activities"
  def table_from_user_relation(:repositories), do: "repository_activities"
  def table_from_user_relation(:transactions), do: "transaction_activities"
end
