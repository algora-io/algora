defmodule Algora.Installations do
  alias Algora.Repo
  alias Algora.Installations.Installation

  def create_installation(params) do
    %Installation{}
    |> Installation.changeset(params)
    |> Repo.insert()
  end

  def update_installation(installation, params) do
    installation
    |> Installation.changeset(params)
    |> Repo.update()
  end

  def get_installation_by(fields), do: Repo.get_by(Installation, fields)
  def get_installation_by!(fields), do: Repo.get_by!(Installation, fields)

  def get_installation_by_provider_id(provider, provider_id),
    do: get_installation_by(provider: provider, provider_id: provider_id)

  def get_installation_by_provider_id!(provider, provider_id),
    do: get_installation_by!(provider: provider, provider_id: provider_id)

  def get_installation(id), do: Repo.get(Installation, id)
  def get_installation!(id), do: Repo.get!(Installation, id)
end
