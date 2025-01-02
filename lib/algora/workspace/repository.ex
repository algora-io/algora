defmodule Algora.Workspace.Repository do
  @moduledoc false
  use Algora.Schema

  alias Algora.Workspace.Repository

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "repositories" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :name, :string
    field :url, :string

    has_many :tickets, Algora.Workspace.Ticket
    belongs_to :user, Algora.Users.User

    timestamps()
  end

  def github_changeset(meta, user) do
    params = %{
      provider_id: to_string(meta["id"]),
      name: meta["name"],
      url: meta["html_url"],
      user_id: user.id
    }

    %Repository{provider: "github", provider_meta: meta}
    |> cast(params, [:provider_id, :name, :url, :user_id])
    |> generate_id()
    |> validate_required([:provider_id, :name, :url, :user_id])
    |> unique_constraint([:provider, :provider_id])
  end
end
