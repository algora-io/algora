defmodule Algora.Activities do
  @moduledoc false
  import Ecto.Query

  alias Algora.Activities.Activity
  alias Algora.Repo

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
    :contractor_contracts
  ]

  def tables, do: @tables
  def user_attributes, do: @user_attributes

  def base_query do
    [head | tail] = @tables

    query = head |> to_string() |> base_query()

    Enum.reduce(tail, query, fn table_name, acc ->
      new_query = table_name |> to_string() |> base_query()
      union_all(new_query, ^acc)
    end)
  end

  def base_query(table_name) do
    from(_e in {table_name, Activity})
  end

  def base_query_for_user(user_id) do
    [head | tail] = @user_attributes
    first_query = base_query_for_user(user_id, head)

    Enum.reduce(tail, first_query, fn relation_name, acc ->
      new_query = base_query_for_user(user_id, relation_name)
      union_all(new_query, ^acc)
    end)
  end

  def base_query_for_user(user_id, name) do
    from u in Algora.Accounts.User,
      where: u.id == ^user_id,
      join: c in assoc(u, ^name),
      join: a in assoc(c, :activities),
      select: a
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
    |> Repo.all()
  end

  def all_for_user(user_id) do
    user_id
    |> base_query_for_user()
    |> order_by(fragment("inserted_at DESC"))
    |> limit(40)
    |> Repo.all()
  end

  def insert(target, activity) do
    target
    |> Activity.build_activity(activity)
    |> Algora.Repo.insert()
  end
end
