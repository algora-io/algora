defmodule Algora.Workspace.Repository do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity
  alias Algora.Workspace.Repository

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "repositories" do
    field :provider, :string, null: false
    field :provider_id, :string, null: false
    field :provider_meta, :map, null: false

    field :name, :string, null: false
    field :url, :string, null: false
    field :description, :string
    field :og_image_url, :string, null: false
    field :og_image_updated_at, :utc_datetime_usec

    has_many :tickets, Algora.Workspace.Ticket
    has_many :activities, {"repository_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore
    belongs_to :user, Algora.Accounts.User, null: false

    timestamps()
  end

  defp og_image_base_url, do: "https://opengraph.githubassets.com"

  def has_default_og_image?(%Repository{} = repository),
    do: String.starts_with?(repository.og_image_url, og_image_base_url())

  def default_og_image_url(repo_owner, repo_name), do: "#{og_image_base_url()}/0/#{repo_owner}/#{repo_name}"

  def github_changeset(meta, user) do
    params = %{
      provider_id: to_string(meta["id"]),
      name: meta["name"],
      description: meta["description"],
      og_image_url: default_og_image_url(meta["owner"]["login"], meta["name"]),
      og_image_updated_at: DateTime.utc_now(),
      url: meta["html_url"],
      user_id: user.id
    }

    %Repository{provider: "github", provider_meta: meta}
    |> cast(params, [:provider_id, :name, :url, :description, :og_image_url, :og_image_updated_at, :user_id])
    |> generate_id()
    |> validate_required([:provider_id, :name, :url, :user_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:provider, :provider_id])
  end
end
