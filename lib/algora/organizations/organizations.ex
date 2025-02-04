defmodule Algora.Organizations do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Contracts.Contract
  alias Algora.Organizations.Member
  alias Algora.Organizations.Org
  alias Algora.Repo
  alias Ecto.Multi

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
    org_changeset = Org.changeset(%User{type: :organization}, params.organization)

    user_changeset = User.org_registration_changeset(%User{type: :individual}, params.user)

    Multi.new()
    |> Multi.insert(:org, org_changeset)
    |> Multi.insert(:user, user_changeset)
    |> Multi.merge(fn %{user: user, org: org} ->
      member_changeset =
        Member.changeset(
          %Member{},
          Map.merge(params.member, %{user: user, org: org})
        )

      contract_changeset =
        Contract.draft_changeset(
          %Contract{},
          Map.put(params.contract, :client_id, org.id)
        )

      Multi.new()
      |> Multi.insert(:member, member_changeset)
      |> Multi.insert(:contract, contract_changeset)
    end)
    |> Repo.transaction()
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
        }
    )
  end

  def list_org_contractors(org) do
    Repo.all(
      from u in User,
        join: c in assoc(u, :contractor_contracts),
        where: c.client_id == ^org.id and c.contractor_id == u.id
    )
  end
end
