defmodule Algora.Work.Repository do
  use Ecto.Schema
  import Ecto.Changeset

  schema "repositories" do
    field :name, :string
    field :url, :string

    has_many :tasks, Algora.Work.Task
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:name, :url])
    |> validate_required([:name, :url])
  end
end
