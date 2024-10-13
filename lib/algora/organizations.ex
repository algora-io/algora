defmodule Algora.Organizations do
  import Ecto.Query
  import Ecto.Changeset

  alias Algora.Accounts.User
  alias Algora.Organizations.Org
  alias Algora.Organizations.Member
  alias Algora.Repo

  def create_organization(params) do
    %User{}
    |> Org.changeset(params)
    |> put_change(:type, :organization)
    |> Repo.insert()
  end

  def update_organization(org, params) do
    org
    |> Org.changeset(params)
    |> Repo.update()
  end

  def create_member(org, user, role) do
    %Member{}
    |> Member.changeset(%{role: role, org_id: org.id, user_id: user.id})
    |> Repo.insert()
  end

  def get_org_by(fields), do: Repo.get_by(User, fields)
  def get_org_by!(fields), do: Repo.get_by!(User, fields)

  def get_org_by_handle(handle), do: get_org_by(handle: handle)
  def get_org_by_handle!(handle), do: get_org_by!(handle: handle)

  def get_org(id), do: Repo.get(User, id)
  def get_org!(id), do: Repo.get!(User, id)

  def list_orgs(opts) do
    Repo.all(
      from u in User,
        where: u.type == "organization",
        limit: ^Keyword.fetch!(opts, :limit)
    )
  end
end
