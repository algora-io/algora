defmodule Algora.Activities do
  @moduledoc false
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Activities.Activity
  alias Algora.Repo

  @tables [
    :account_activities,
    :contract_activities
  ]

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
    [head | tail] = [:client_contracts, :contractor_contracts]
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
    Repo.all(Ecto.assoc(target, :activities))
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
