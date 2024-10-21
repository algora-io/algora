defmodule Algora.Installations do
  import Ecto.Query

  alias Algora.Repo
  alias Algora.Installations.Installation

  def create_installation(:github, user, org, data) do
    %Installation{}
    |> Installation.changeset(:github, user, org, data)
    |> Repo.insert()
  end

  def update_installation(:github, user, org, installation, data) do
    installation
    |> Installation.changeset(:github, user, org, data)
    |> Repo.update()
  end

  def get_installation_by(fields), do: Repo.get_by(Installation, fields)
  def get_installation_by!(fields), do: Repo.get_by!(Installation, fields)

  @type provider_id :: String.t() | integer()

  @spec get_installation_by_provider_id(String.t(), provider_id()) :: Installation.t() | nil
  def get_installation_by_provider_id(provider, provider_id),
    do: get_installation_by(provider: provider, provider_id: to_string(provider_id))

  @spec get_installation_by_provider_id!(String.t(), provider_id()) :: Installation.t()
  def get_installation_by_provider_id!(provider, provider_id),
    do: get_installation_by!(provider: provider, provider_id: to_string(provider_id))

  def get_installation(id), do: Repo.get(Installation, id)
  def get_installation!(id), do: Repo.get!(Installation, id)

  def list_user_installations(user_id) do
    Repo.all(from(i in Installation, where: i.owner_id == ^user_id, preload: [:connected_user]))
  end
end
