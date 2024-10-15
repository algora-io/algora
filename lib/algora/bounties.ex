defmodule Algora.Bounties do
  import Ecto.Query

  alias Algora.Bounties.Bounty
  alias Algora.Repo
  alias Algora.Accounts
  alias Algora.Work
  alias Algora.Accounts.User

  @spec create_bounty(
          creator :: User.t(),
          owner :: User.t(),
          url :: String.t(),
          amount :: Decimal.t()
        ) ::
          {:ok, Bounty.t()} | {:error, atom()}
  def create_bounty(creator = %User{}, owner = %User{}, url, amount) do
    with {:ok, token} <- Accounts.get_access_token(creator),
         {:ok, task} <- Work.fetch_task(:github, %{token: token, url: url}) do
      %Bounty{}
      |> Bounty.changeset(%{
        amount: Decimal.new(amount),
        currency: "USD",
        task_id: task.id,
        owner_id: owner.id,
        creator_id: creator.id
      })
      |> Repo.insert()
    else
      error -> error
    end
  end

  @spec list_bounties(
          params :: %{optional(:owner_id) => integer(), optional(:limit) => non_neg_integer()}
        ) :: [map()]
  def list_bounties(params) do
    limit = params[:limit] || 10

    query =
      from b in Bounty,
        join: t in assoc(b, :task),
        join: r in assoc(t, :repository),
        join: u in assoc(r, :user),
        select: %{
          id: b.id,
          inserted_at: b.inserted_at,
          amount: b.amount,
          currency: b.currency,
          task: %{
            title: t.title,
            owner: u.provider_login,
            repo: r.name,
            number: t.number
          }
        },
        limit: ^limit,
        order_by: [desc: b.inserted_at, desc: b.id]

    query
    |> maybe_filter_by_owner_id(params[:owner_id])
    |> Repo.all()
  end

  defp maybe_filter_by_owner_id(query, nil), do: query

  defp maybe_filter_by_owner_id(query, owner_id) do
    from [b, t] in query,
      where: b.owner_id == ^owner_id
  end
end
