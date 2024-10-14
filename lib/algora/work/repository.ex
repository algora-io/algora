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

  def changeset(:github, attrs) do
    %Repository{provider: "github", provider_id: to_string(attrs["id"]), provider_meta: attrs}
    |> cast(
      %{
        name: attrs["name"],
        url: attrs["url"]
      },
      [:name, :url]
    )
    |> validate_required([:name, :url])
  end
end
