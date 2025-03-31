defmodule Algora.Accounts.Identity do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Activities.Activity

  @derive {Inspect, except: [:provider_token, :provider_meta]}
  typed_schema "identities" do
    field :provider, :string
    field :provider_token, :string
    field :provider_email, :string
    field :provider_login, :string
    field :provider_name, :string, virtual: true
    field :provider_id, :string
    field :provider_meta, :map

    belongs_to :user, User

    has_many :activities, {"identity_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  @doc """
  A user changeset for github registration.
  """
  def github_registration_changeset(nil, info, primary_email, emails, token) do
    params = %{
      "provider_token" => token,
      "provider_id" => to_string(info["id"]),
      "provider_login" => info["login"],
      "provider_name" => info["name"] || info["login"],
      "provider_email" => primary_email
    }

    %Identity{provider: "github", provider_meta: %{"user" => info, "emails" => emails}}
    |> cast(params, [
      :provider_token,
      :provider_email,
      :provider_login,
      :provider_name,
      :provider_id
    ])
    |> generate_id()
    |> validate_required([:provider_token, :provider_email, :provider_name, :provider_id])
    |> validate_length(:provider_meta, max: 10_000)
  end

  def github_registration_changeset(user, info, primary_email, emails, token) do
    params = %{
      "provider_token" => token,
      "provider_id" => to_string(info["id"]),
      "provider_login" => info["login"],
      "provider_name" => info["name"] || info["login"],
      "provider_email" => primary_email
    }

    %Identity{
      provider: "github",
      provider_meta: %{"user" => info, "emails" => emails},
      user_id: user.id
    }
    |> cast(params, [
      :provider_token,
      :provider_email,
      :provider_login,
      :provider_name,
      :provider_id
    ])
    |> generate_id()
    |> validate_required([:provider_token, :provider_email, :provider_name, :provider_id])
    |> validate_length(:provider_meta, max: 10_000)
  end
end
