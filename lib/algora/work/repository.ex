defmodule Algora.Work.Repository do
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Work.Repository
  @derive {Inspect, except: [:provider_meta]}
  schema "repositories" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :name, :string
    field :url, :string

    has_many :tasks, Algora.Work.Task
    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def github_changeset(user, meta) do
    params = %{
      provider_id: to_string(meta["id"]),
      name: meta["name"],
      url: meta["html_url"],
      user_id: user.id
    }

    %Repository{provider: "github", provider_meta: meta}
    |> cast(params, [:provider_id, :name, :url, :user_id])
    |> validate_required([:provider_id, :name, :url, :user_id])
    |> unique_constraint([:provider, :provider_id])
  end
end
