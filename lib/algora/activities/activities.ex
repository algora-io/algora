defmodule Algora.Activities do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Activities.Activity
  alias Algora.Bounties.Bounty
  alias Algora.Repo

  @schema_from_table %{
    identity_activities: Identity,
    user_activities: Algora.Accounts.User,
    attempt_activities: Algora.Bounties.Attempt,
    bonus_activities: Algora.Bounties.Bonus,
    bounty_activities: Bounty,
    claim_activities: Algora.Bounties.Claim,
    tip_activities: Algora.Bounties.Tip,
    message_activities: Algora.Chat.Message,
    thread_activities: Algora.Chat.Thread,
    contract_activities: Algora.Contracts.Contract,
    timesheet_activities: Algora.Contracts.Timesheet,
    application_activities: Algora.Jobs.Application,
    job_activities: Algora.Jobs.Job,
    account_activities: Algora.Payments.Account,
    customer_activities: Algora.Payments.Customer,
    payment_method_activities: Algora.Payments.PaymentMethod,
    platform_transaction_activities: Algora.Payments.PlatformTransaction,
    transaction_activities: Algora.Payments.Transaction,
    project_activities: Algora.Projects.Project,
    review_activities: Algora.Reviews.Project,
    installation_activities: Algora.Workplace.Installation,
    ticket_activities: Algora.Workspace.Ticket,
    repository_activities: Algora.Workspace.Repository
  }

  @table_from_user_relation %{
    # attempts: "attempt_activities",
    claims: "claim_activities",
    client_contracts: "contract_activities",
    connected_installations: "installation_activities",
    contractor_contracts: "contract_activities",
    created_bounties: "bounty_activities",
    # owned_bounties: "bounty_activities",
    created_tips: "tip_activities",
    # owned_tips: "tip_activities",
    received_tips: "tip_activities",
    identities: "identity_activities",
    owned_installations: "installation_activities",
    # projects: "project_activities",
    repositories: "repository_activities",
    transactions: "transaction_activities"
  }

  @tables Map.keys(@schema_from_table)
  @user_attributes Map.keys(@table_from_user_relation)

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

    from u in User,
      where: u.id == ^user_id,
      join: c in assoc(u, ^relation_name),
      join: a in assoc(c, :activities),
      select: %{
        id: id,
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

  def all_with_assoc(query) do
    activities = Repo.all(query)
    source = Dataloader.Ecto.new(Algora.Repo)
    dataloader = Dataloader.add_source(Dataloader.new(), :db, source)

    loader =
      activities
      |> Enum.reduce(dataloader, fn activity, loader ->
        schema = schema_from_table(activity.assoc_name)
        Dataloader.load(loader, :db, schema, activity.assoc_id)
      end)
      |> Dataloader.run()

    Enum.map(activities, fn activity ->
      schema = schema_from_table(activity.assoc_name)
      assoc = Dataloader.get(loader, :db, schema, activity.assoc_id)
      Map.put(activity, :assoc, assoc)
    end)
  end

  def get(table, id) do
    query =
      from a in table,
        where: a.id == ^id,
        select: %{
          id: a.id,
          type: a.type,
          assoc_id: a.assoc_id,
          assoc_name: ^table,
          inserted_at: a.inserted_at
        }

    Algora.Repo.one(query)
  end

  def get_assoc(prefix, assoc_id) when prefix in ["bounty_activities"] do
    get_assoc(prefix, assoc_id, [:owner])
  end

  def get_assoc(prefix, assoc_id) when prefix in ["identity_activities"] do
    get_assoc(prefix, assoc_id, [:user])
  end

  def get_assoc(prefix, assoc_id, preload) do
    assoc_table = schema_from_table(prefix)

    query =
      from a in assoc_table,
        preload: ^preload,
        where: a.id == ^assoc_id

    Algora.Repo.one(query)
  end

  def get_with_assoc(table, id) do
    with %{assoc_id: assoc_id} = activity <- get(table, id),
         assoc when is_map(assoc) <- get_assoc(table, assoc_id) do
      Map.put(activity, :assoc, assoc)
    end
  end

  def assoc_url(table, id) do
    activity = get_with_assoc(table, id)
    build_url(activity)
  end

  def schema_from_table(name) when is_binary(name), do: name |> String.to_atom() |> schema_from_table()

  def schema_from_table(name) when is_atom(name) do
    Map.fetch!(@schema_from_table, name)
  end

  def table_from_user_relation(table) do
    Map.fetch!(@table_from_user_relation, table)
  end

  def build_url(%{assoc: %Bounty{owner: user}}), do: {:ok, "/org/#{user.handle}/bounties"}
  def build_url(%{assoc: %Identity{user: %{type: :individual} = user}}), do: {:ok, "/@/#{user.handle}"}
  def build_url(%{assoc: %Identity{user: %{type: :organization} = user}}), do: {:ok, "/org/#{user.handle}"}

  def build_url(_activity) do
    {:error, :not_found}
  end
end
