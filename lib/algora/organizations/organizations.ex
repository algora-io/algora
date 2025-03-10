defmodule Algora.Organizations do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Organizations.Member
  alias Algora.Organizations.Org
  alias Algora.Repo

  def create_organization(params) do
    %User{type: :organization}
    |> Org.changeset(params)
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

  def onboard_organization(params) do
    Repo.transact(fn repo ->
      {:ok, org} =
        case repo.get_by(User, handle: params.organization.handle) do
          nil ->
            %User{type: :organization}
            |> Org.changeset(params.organization)
            |> repo.insert()

          existing_org ->
            existing_org
            |> Org.changeset(params.organization)
            |> repo.update()
        end

      {:ok, user} =
        case repo.get_by(User, email: params.user.email) do
          nil ->
            %User{type: :individual}
            |> User.org_registration_changeset(params.user)
            |> repo.insert()

          existing_user ->
            existing_user
            |> User.org_registration_changeset(params.user)
            |> repo.update()
        end

      {:ok, member} =
        case repo.get_by(Member, user_id: user.id, org_id: org.id) do
          nil ->
            %Member{}
            |> Member.changeset(Map.merge(params.member, %{user_id: user.id, org_id: org.id}))
            |> repo.insert()

          existing_member ->
            existing_member
            |> Member.changeset(Map.merge(params.member, %{user_id: user.id, org_id: org.id}))
            |> repo.update()
        end

      {:ok, %{org: org, user: user, member: member}}
    end)
  end

  def get_org_by(fields), do: Repo.get_by(User, fields)
  def get_org_by!(fields), do: Repo.get_by!(User, fields)

  def get_org_by_handle(handle), do: get_org_by(handle: handle)
  def get_org_by_handle!(handle), do: get_org_by!(handle: handle)

  def get_org(id), do: Repo.get(User, id)
  def get_org!(id), do: Repo.get!(User, id)

  @spec fetch_org_by(clauses :: Keyword.t() | map()) ::
          {:ok, User.t()} | {:error, :not_found}
  def fetch_org_by(clauses) do
    Repo.fetch_by(User, clauses)
  end

  def list_orgs(opts) do
    Repo.all(
      from u in User,
        where: u.type == :organization,
        limit: ^Keyword.fetch!(opts, :limit)
    )
  end

  def get_user_orgs(%User{} = user) do
    Repo.all(
      from o in User,
        join: m in assoc(o, :members),
        where: m.user_id == ^user.id and m.org_id == o.id
    )
  end

  def list_org_members(org) do
    Repo.all(
      from m in Member,
        join: u in assoc(m, :user),
        where: m.org_id == ^org.id and m.user_id == u.id,
        select_merge: %{
          user: u
        },
        order_by: [
          fragment(
            "CASE WHEN ? = 'admin' THEN 0 WHEN ? = 'mod' THEN 1 WHEN ? = 'expert' THEN 2 ELSE 3 END",
            m.role,
            m.role,
            m.role
          ),
          asc: m.inserted_at,
          asc: m.id
        ]
    )
  end

  def fetch_member(org_id, user_id) do
    Repo.fetch_by(Member, org_id: org_id, user_id: user_id)
  end

  def list_org_contractors(org) do
    Repo.all(
      from u in User,
        distinct: true,
        join: c in assoc(u, :contractor_contracts),
        where: c.client_id == ^org.id and c.contractor_id == u.id
    )
  end
end
