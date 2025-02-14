defmodule Algora.Workspace.Installation do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Activities.Activity

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "installations" do
    field :provider, :string, null: false
    field :provider_id, :string, null: false
    field :provider_meta, :map
    field :provider_user_id, :string

    field :avatar_url, :string
    field :repository_selection, :string

    belongs_to :owner, User, null: false
    belongs_to :connected_user, User, null: false

    has_many :activities, {"installation_activities", Activity}, foreign_key: :assoc_id
    timestamps()
  end

  def github_changeset(installation, user, provider_user, org, data) do
    params = %{
      owner_id: user.id,
      connected_user_id: org.id,
      avatar_url: data["account"]["avatar_url"],
      repository_selection: data["repository_selection"],
      provider_id: to_string(data["id"]),
      provider_user_id: to_string(provider_user.id),
      provider_meta: data
    }

    installation
    |> cast(params, [
      :owner_id,
      :connected_user_id,
      :avatar_url,
      :repository_selection,
      :provider_id,
      :provider_user_id,
      :provider_meta
    ])
    |> validate_required([:owner_id, :connected_user_id, :provider_id, :provider_user_id, :provider_meta])
    |> generate_id()
    |> foreign_key_constraint(:owner_id)
    |> foreign_key_constraint(:connected_user_id)
    |> unique_constraint([:provider, :provider_id])
    |> put_change(:provider, "github")
    |> put_change(:provider_meta, data)
  end
end
