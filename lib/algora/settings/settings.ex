defmodule Algora.Settings do
  @moduledoc false
  use Ecto.Schema

  alias Algora.Repo

  @primary_key {:key, :string, []}
  schema "settings" do
    field :value, :map
    timestamps()
  end

  def get(key) do
    case Repo.get(__MODULE__, key) do
      nil -> nil
      config -> config.value
    end
  end

  def set(key, value) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(%{key: key, value: value}, [:key, :value])
    |> Ecto.Changeset.validate_required([:key, :value])
    |> Repo.insert(on_conflict: {:replace, [:value]}, conflict_target: :key)
  end

  def set!(key, value) do
    case set(key, value) do
      {:ok, _} -> :ok
      {:error, reason} -> raise "Failed to set #{key} to #{value}: #{reason}"
    end
  end

  def delete(key) do
    case Repo.get(__MODULE__, key) do
      nil -> {:ok, nil}
      config -> Repo.delete(config)
    end
  end

  def get_featured_developers do
    case get("featured_developers") do
      %{"handles" => handles} when is_list(handles) -> handles
      _ -> nil
    end
  end

  def set_featured_developers(handles) when is_list(handles) do
    set("featured_developers", %{"handles" => handles})
  end

  def migration_in_progress? do
    case get("migration_in_progress") do
      %{"active" => active} when is_boolean(active) -> active
      _ -> false
    end
  end

  def set_migration_in_progress!(active) when is_boolean(active) do
    set!("migration_in_progress", %{"active" => active})
  end
end
