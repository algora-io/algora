defmodule Algora.Repo do
  use Ecto.Repo,
    otp_app: :algora,
    adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  @spec fetch_one(Ecto.Queryable.t(), Keyword.t()) ::
          {:ok, struct()} | {:error, :not_found}
  def fetch_one(queryable, opts \\ []) do
    case all(queryable, opts) do
      [record] -> {:ok, record}
      _none_or_multiple_records -> {:error, :not_found}
    end
  end

  @spec fetch(Ecto.Queryable.t(), term(), Keyword.t()) ::
          {:ok, struct()} | {:error, :not_found}
  def fetch(queryable, id, opts \\ []) do
    schema =
      case queryable do
        schema when is_atom(schema) ->
          schema

        queryable ->
          {_, schema} = queryable.from.source
          schema
      end

    [pk] = schema.__schema__(:primary_key)

    query =
      Ecto.Query.from(q in queryable,
        where: field(q, ^pk) == ^id
      )

    fetch_one(query, opts)
  end

  @spec fetch_by(Ecto.Queryable.t(), Keyword.t() | map(), Keyword.t()) ::
          {:ok, struct()} | {:error, :not_found}
  def fetch_by(queryable, clauses, opts \\ []) do
    query =
      Enum.reduce(clauses, queryable, fn {k, v}, queryable ->
        Ecto.Query.from(q in queryable,
          where: field(q, ^k) == ^v
        )
      end)

    fetch_one(query, opts)
  end

  @spec transact(fun(), Keyword.t()) :: term()
  def transact(fun, opts \\ []) do
    transaction(
      fn repo ->
        result =
          case Function.info(fun, :arity) do
            {:arity, 0} -> fun.()
            {:arity, 1} -> fun.(repo)
          end

        case result do
          {:ok, result} -> result
          {:error, reason} -> repo.rollback(reason)
        end
      end,
      opts
    )
  end

  @spec insert_with_activity(Ecto.Changeset.t(), struct()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def insert_with_activity(changeset, activity) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:target, changeset)
    |> with_activity(activity)
    |> transaction()
    |> extract_target()
  end

  @spec update_with_activity(Ecto.Changeset.t(), struct()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def update_with_activity(changeset, activity) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:target, changeset)
    |> with_activity(activity)
    |> transaction()
    |> extract_target()
  end

  @spec delete_with_activity(Ecto.Changeset.t(), struct()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def delete_with_activity(changeset, activity) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:target, changeset)
    |> with_activity(activity)
    |> transaction()
    |> extract_target()
  end

  @spec with_activity(Ecto.Multi.t(), struct()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def with_activity(multi, activity) do
    multi
    |> Ecto.Multi.insert(:activity, fn %{target: target} ->
      Algora.Activities.Activity.build_activity(target, Map.put(activity, :id, target.id))
    end)
    |> Oban.insert(:notification, fn %{activity: activity, target: target} ->
      Algora.Activities.Notifier.changeset(activity, target)
    end)
  end

  defp extract_target(response) do
    case response do
      {:ok, %{target: target}} -> {:ok, target}
      {:error, %{target: target}} -> {:error, target}
      {:error, error} -> {:error, error}
    end
  end
end
