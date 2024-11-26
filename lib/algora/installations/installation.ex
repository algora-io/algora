defmodule Algora.Installations.Installation do
  use Algora.Model

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "installations" do
    field :provider, :string
    field :provider_id, :string
    field :provider_login, :string
    field :provider_meta, :map

    field :avatar_url, :string
    field :repository_selection, :string

    belongs_to :owner, Algora.Users.User
    belongs_to :connected_user, Algora.Users.User

    timestamps()
  end

  def changeset(installation, :github, user, org, data) do
    params = %{
      owner_id: user.id,
      connected_user_id: org.id,
      avatar_url: data["account"]["avatar_url"],
      repository_selection: data["repository_selection"],
      provider_id: to_string(data["id"]),
      provider_login: data["account"]["login"]
    }

    installation
    |> cast(params, [
      :owner_id,
      :connected_user_id,
      :avatar_url,
      :repository_selection,
      :provider_id,
      :provider_login
    ])
    |> validate_required([:owner_id, :connected_user_id, :provider_id, :provider_login])
    |> generate_id()
    |> put_change(:provider, "github")
    |> put_change(:provider_meta, data)
  end
end
