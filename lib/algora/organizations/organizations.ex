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
      {:ok, user} =
        case repo.get_by(User, email: params.user.email) do
          nil ->
            handle = generate_unique_handle(repo, params.user.handle)

            %User{type: :individual}
            |> User.org_registration_changeset(Map.put(params.user, :handle, handle))
            |> repo.insert()

          existing_user ->
            existing_user
            |> User.org_registration_changeset(Map.delete(params.user, :handle))
            |> repo.update()
        end

      {:ok, org} =
        case repo.one(
               from o in User,
                 join: m in assoc(o, :members),
                 join: u in assoc(m, :user),
                 where: o.handle in ^generate_unique_org_handle_candidates(params.organization.handle),
                 where: u.id == ^user.id,
                 limit: 1
             ) do
          nil ->
            handle = generate_unique_org_handle(repo, params.organization.handle)

            %User{type: :organization}
            |> Org.changeset(Map.put(params.organization, :handle, handle))
            |> repo.insert()

          existing_org ->
            existing_org
            |> Org.changeset(Map.delete(params.organization, :handle))
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

  defp generate_unique_handle(repo, base_handle) do
    0
    |> Stream.iterate(&(&1 + 1))
    |> Enum.reduce_while(base_handle, fn i, _handle -> {:halt, increment_handle(repo, base_handle, i)} end)
  end

  defp generate_unique_org_handle_candidates(base_handle) do
    suffixes = ["hq", "team", "app", "labs", "co"]
    prefixes = ["get", "try", "join", "go"]

    List.flatten(
      [base_handle] ++
        Enum.map(suffixes, &"#{base_handle}#{&1}") ++
        Enum.map(prefixes, &"#{&1}#{base_handle}")
    )
  end

  defp generate_unique_org_handle(repo, base_handle) do
    case try_candidates(repo, base_handle) do
      nil -> increment_handle(repo, base_handle, 1)
      handle -> handle
    end
  end

  defp try_candidates(repo, base_handle) do
    candidates = generate_unique_org_handle_candidates(base_handle)

    Enum.reduce_while(candidates, nil, fn candidate, _acc ->
      case repo.get_by(User, handle: candidate) do
        nil -> {:halt, candidate}
        _user -> {:cont, nil}
      end
    end)
  end

  defp increment_handle(repo, base_handle, n) do
    candidate =
      case n do
        0 -> base_handle
        n when n <= 42 -> "#{base_handle}#{n}"
        _ -> raise "Too many attempts to generate unique handle"
      end

    case repo.get_by(User, handle: candidate) do
      nil -> candidate
      _user -> increment_handle(repo, base_handle, n + 1)
    end
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
        limit: ^opts[:limit]
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
