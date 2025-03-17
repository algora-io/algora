defmodule Algora.Admin.Mainthings do
  @moduledoc false

  import Ecto.Query

  alias Algora.Admin.Mainthings.Mainthing
  alias Algora.Repo

  @doc """
  Gets the latest mainthing entry.
  """
  def get_latest do
    Mainthing
    |> last(:inserted_at)
    |> Repo.one()
  end

  @doc """
  Creates a new mainthing entry.
  """
  def create(attrs \\ %{}) do
    %Mainthing{}
    |> Mainthing.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a mainthing entry.
  """
  def update(%Mainthing{} = mainthing, attrs) do
    mainthing
    |> Mainthing.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a mainthing entry.
  """
  def delete(%Mainthing{} = mainthing) do
    Repo.delete(mainthing)
  end
end
