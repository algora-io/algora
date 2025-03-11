defmodule Algora.Activities do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Activities.Activity
  alias Algora.Activities.DiscordViews
  alias Algora.Activities.Router
  alias Algora.Activities.Views
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
    account_activities: Algora.Payments.Account,
    customer_activities: Algora.Payments.Customer,
    payment_method_activities: Algora.Payments.PaymentMethod,
    platform_transaction_activities: Algora.Payments.PlatformTransaction,
    transaction_activities: Algora.Payments.Transaction,
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
    repositories: "repository_activities",
    transactions: "transaction_activities"
  }

  @table_from_schema Map.new(@schema_from_table, &{elem(&1, 1), elem(&1, 0)})
  @tables Map.keys(@schema_from_table)
  @user_attributes Map.keys(@table_from_user_relation)

  def schema_from_table(name) when is_binary(name), do: name |> String.to_atom() |> schema_from_table()

  def schema_from_table(name) when is_atom(name) do
    Map.fetch!(@schema_from_table, name)
  end

  def table_from_schema(name) when is_binary(name), do: name |> String.to_atom() |> table_from_schema()

  def table_from_schema(name) when is_atom(name) do
    Map.fetch!(@table_from_schema, name)
  end

  def table_from_user_relation(table) do
    Map.fetch!(@table_from_user_relation, table)
  end

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
    assoc_query =
      from t in schema_from_table(table),
        where: parent_as(:activity).assoc_id == t.id

    query =
      from a in table,
        as: :activity,
        where: a.id == ^id,
        inner_lateral_join: t in subquery(assoc_query),
        on: true,
        select: %{
          id: a.id,
          type: a.type,
          assoc_id: a.assoc_id,
          assoc_name: ^table,
          assoc: t,
          notify_users: a.notify_users,
          visibility: a.visibility,
          template: a.template,
          meta: a.meta,
          changes: a.changes,
          trace_id: a.trace_id,
          previous_event_id: a.previous_event_id,
          inserted_at: a.inserted_at,
          updated_at: a.updated_at
        }

    struct(Activity, Algora.Repo.one(query))
  end

  def get_with_preloaded_assoc(table, id) do
    schema = schema_from_table(table)

    with %{assoc_id: assoc_id} = activity <- get(table, id),
         assoc when is_map(assoc) <- get_preloaded_assoc(schema, assoc_id) do
      Map.put(activity, :assoc, assoc)
    end
  end

  def get_preloaded_assoc(schema, assoc_id) do
    query =
      if Kernel.function_exported?(schema, :preload, 1) do
        schema.preload(assoc_id)
      else
        from a in schema, where: a.id == ^assoc_id
      end

    Algora.Repo.one(query)
  end

  def assoc_url(table, id) do
    table |> get(id) |> Router.route()
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Algora.PubSub, "activities")
  end

  def subscribe(schema) when is_atom(schema) do
    schema |> schema_from_table() |> subscribe()
  end

  def subscribe_table(table) when is_binary(table) do
    Phoenix.PubSub.subscribe(Algora.PubSub, "activity:table:#{table}")
  end

  def subscribe_user(user_id) when is_binary(user_id) do
    Phoenix.PubSub.subscribe(Algora.PubSub, "activity:users:#{user_id}")
  end

  def broadcast(%{notify_users: []}), do: []

  def broadcast(%{notify_users: user_ids} = activity) do
    :ok = Phoenix.PubSub.broadcast(Algora.PubSub, "activities", activity)
    :ok = Phoenix.PubSub.broadcast(Algora.PubSub, "activity:table:#{activity.assoc_name}", activity)

    users_query =
      from u in Algora.Accounts.User,
        where: u.id in ^user_ids,
        select: u

    users_query
    |> Algora.Repo.all()
    |> Enum.reduce([], fn user, not_online ->
      # TODO setup notification preferences
      :ok = Phoenix.PubSub.broadcast(Algora.PubSub, "activity:users:#{user.id}", activity)
      [user | not_online]
    end)
  end

  def notify_users(activity, users_to_notify) do
    title = Views.render(activity, :title)
    body = Views.render(activity, :txt)

    email_jobs =
      Enum.reduce(users_to_notify, [], fn
        %{name: display_name, email: email, id: id}, acc ->
          changeset =
            Algora.Activities.SendEmail.changeset(%{
              title: title,
              body: body,
              user_id: id,
              activity_id: activity.id,
              activity_type: activity.type,
              activity_table: activity.assoc_name,
              name: display_name,
              email: email
            })

          [changeset | acc]

        _user, acc ->
          acc
      end)

    discord_job =
      if discord_payload = DiscordViews.render(activity) do
        [Algora.Activities.SendDiscord.changeset(%{payload: discord_payload})]
      else
        []
      end

    Oban.insert_all(email_jobs ++ discord_job)
  end

  def redirect_url_for_activity(activity) do
    slug =
      activity.assoc_name
      |> to_string()
      |> String.replace("_activities", "")

    "a/#{slug}/#{activity.id}"
  end

  def external_url(activity) do
    path = redirect_url_for_activity(activity)
    "#{AlgoraWeb.Endpoint.url()}/#{path}"
  end

  def activity_type_to_name(type) do
    type
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize(&1))
  end
end
