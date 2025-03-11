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

  def delete(key) do
    case Repo.get(__MODULE__, key) do
      nil -> {:ok, nil}
      config -> Repo.delete(config)
    end
  end
end
