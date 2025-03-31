defmodule Algora.Organizations do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Organizations.Member
  alias Algora.Organizations.Org
  alias Algora.Repo
  alias Algora.Workspace

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
    Repo.transact(fn ->
      {:ok, user} =
        case Repo.get_by(User, email: params.user.email) do
          nil ->
            handle = ensure_unique_handle(params.user.handle)

            %User{type: :individual}
            |> User.org_registration_changeset(Map.put(params.user, :handle, handle))
            |> Repo.insert()

          existing_user ->
            existing_user
            |> User.org_registration_changeset(Map.delete(params.user, :handle))
            |> Repo.update()
        end

      {:ok, org} =
        case Repo.one(
               from o in User,
                 join: m in assoc(o, :members),
                 join: u in assoc(m, :user),
                 where: o.handle in ^generate_unique_org_handle_candidates(params.organization.handle),
                 where: u.id == ^user.id,
                 limit: 1
             ) do
          nil ->
            handle = ensure_unique_org_handle(params.organization.handle)

            %User{type: :organization}
            |> Org.changeset(Map.put(params.organization, :handle, handle))
            |> Repo.insert()

          existing_org ->
            existing_org
            |> Org.changeset(Map.delete(params.organization, :handle))
            |> Repo.update()
        end

      {:ok, member} =
        case Repo.get_by(Member, user_id: user.id, org_id: org.id) do
          nil ->
            %Member{}
            |> Member.changeset(Map.merge(params.member, %{user_id: user.id, org_id: org.id}))
            |> Repo.insert()

          existing_member ->
            existing_member
            |> Member.changeset(Map.merge(params.member, %{user_id: user.id, org_id: org.id}))
            |> Repo.update()
        end

      {:ok, %{org: org, user: user, member: member}}
    end)
  end

  def generate_handle_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.split("+")
    |> List.first()
    |> String.replace(~r/[^a-zA-Z0-9]/, "")
    |> String.downcase()
  end

  def ensure_unique_handle(base_handle) do
    0
    |> Stream.iterate(&(&1 + 1))
    |> Enum.reduce_while(base_handle, fn i, _handle -> {:halt, increment_handle(base_handle, i)} end)
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

  def ensure_unique_org_handle(base_handle) do
    case try_candidates(base_handle) do
      nil -> increment_handle(base_handle, 1)
      handle -> handle
    end
  end

  defp try_candidates(base_handle) do
    candidates = generate_unique_org_handle_candidates(base_handle)

    Enum.reduce_while(candidates, nil, fn candidate, _acc ->
      case Repo.get_by(User, handle: candidate) do
        nil -> {:halt, candidate}
        _user -> {:cont, nil}
      end
    end)
  end

  defp increment_handle(base_handle, n) do
    candidate =
      case n do
        0 -> base_handle
        n when n <= 42 -> "#{base_handle}#{n}"
        _ -> raise "Too many attempts to generate unique handle"
      end

    case Repo.get_by(User, handle: candidate) do
      nil -> candidate
      _user -> increment_handle(base_handle, n + 1)
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

  @type criterion ::
          {:limit, non_neg_integer()}
          | {:before, %{priority: integer(), stargazers_count: integer(), id: String.t()}}

  @spec apply_criteria(Ecto.Queryable.t(), [criterion()]) :: Ecto.Queryable.t()
  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from([u] in query, limit: ^limit)

      {:before, %{priority: priority, stargazers_count: stargazers_count, id: id}}, query ->
        from([u] in query,
          where: {u.priority, u.stargazers_count, u.id} < {^priority, ^stargazers_count, ^id}
        )

      _, query ->
        query
    end)
  end

  def list_orgs(opts) do
    orgs_with_open_bounties =
      from b in Algora.Bounties.Bounty,
        where: b.status == :open,
        select: b.owner_id

    orgs_with_transactions =
      from tx in Algora.Payments.Transaction,
        where: tx.status == :succeeded,
        where: tx.type == :debit,
        select: tx.user_id

    User
    |> where([u], u.type == :organization)
    |> where([u], not is_nil(u.handle))
    |> where([u], u.featured == true)
    |> where([u], u.id in subquery(orgs_with_open_bounties) or u.id in subquery(orgs_with_transactions))
    |> order_by([u], desc: u.priority, desc: u.stargazers_count, desc: u.id)
    |> apply_criteria(opts)
    |> Repo.all()
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

  def init_preview(repo_owner, repo_name) do
    token = Algora.Admin.token()

    with {:ok, repo} <- Workspace.ensure_repository(token, repo_owner, repo_name),
         {:ok, owner} <- Workspace.ensure_user(token, repo_owner),
         {:ok, _contributors} <- Workspace.ensure_contributors(token, repo),
         {:ok, _languages} <- Workspace.ensure_repo_tech_stack(token, repo) do
      Repo.transact(fn _ ->
        with {:ok, org} <-
               Repo.insert(%User{
                 type: :organization,
                 id: Nanoid.generate(),
                 display_name: owner.name,
                 avatar_url: owner.avatar_url,
                 last_context: "repo/#{repo_owner}/#{repo_name}",
                 tech_stack: repo.tech_stack
               }),
             {:ok, user} <-
               Repo.insert(%User{
                 type: :individual,
                 id: Nanoid.generate(),
                 display_name: "You",
                 last_context: "preview/#{org.id}/#{repo_owner}/#{repo_name}",
                 tech_stack: repo.tech_stack
               }) do
          Algora.Admin.alert("New preview for #{repo_owner}/#{repo_name}", :info)
          {:ok, %{org: org, user: user}}
        end
      end)
    else
      {:error, error} ->
        Algora.Admin.alert("Error initializing preview for #{repo_owner}/#{repo_name}: #{inspect(error)}", :error)
        {:error, error}
    end
  rescue
    error ->
      Algora.Admin.alert("Error initializing preview for #{repo_owner}/#{repo_name}: #{inspect(error)}", :error)
      {:error, error}
  end
end
