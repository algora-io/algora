defmodule Algora.Admin.Migration.Test do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Payments.Transaction
  alias Algora.Repo

  @doc """
  Example usage:

      Migration.Test.diff_balances("balance-2025-02-13.json")
  """
  def diff_balances(src) do
    diff_balances(:individual, src) ++ diff_balances(:organization, src)
  end

  def diff_balances(type, src) do
    actual = Enum.map(get_actual_balances(type, src), &Map.take(&1, [:provider_login, :balance]))
    current = Enum.map(get_balances(type), &Map.take(&1, [:provider_login, :balance]))

    actual_map = Map.new(actual, &{&1.provider_login, &1.balance})
    current_map = Map.new(current, &{&1.provider_login, &1.balance})

    all_logins =
      MapSet.union(
        MapSet.new(Map.keys(actual_map)),
        MapSet.new(Map.keys(current_map))
      )

    differences =
      Enum.reduce(all_logins, [], fn login, acc ->
        actual_balance = Map.get(actual_map, login)
        current_balance = Map.get(current_map, login)

        cond do
          actual_balance == current_balance ->
            acc

          actual_balance == nil ->
            [{:extra_in_current, login, current_balance} | acc]

          current_balance == nil ->
            [{:missing_in_current, login, actual_balance} | acc]

          true ->
            [{:different, login, actual_balance, current_balance} | acc]
        end
      end)

    Enum.sort_by(differences, &elem(&1, 1))
  end

  defp get_actual_balances(type, src) do
    path = Path.join([:code.priv_dir(:algora), "migration", src])

    with {:ok, content} <- File.read(path),
         {:ok, data} <- Jason.decode(content) do
      Enum.map(data[Atom.to_string(type)], fn %{"provider_login" => login, "balance" => balance} ->
        %{
          provider_login: login,
          balance: Money.new!(:USD, Decimal.new(balance))
        }
      end)
    else
      error -> raise "Failed to load balances: #{inspect(error)}"
    end
  end

  defp get_balances(type) do
    get_balances()
    |> Enum.filter(&(&1.type == type))
    |> Enum.reject(&(&1.provider_login in ["algora-io", "Uber4Coding"]))
  end

  defp get_balances do
    user_txs =
      from t in Transaction,
        group_by: [t.user_id, t.type],
        select: %{
          user_id: t.user_id,
          type: t.type,
          net_amount: sum(t.net_amount)
        }

    user_balances =
      from ut in subquery(user_txs),
        group_by: ut.user_id,
        select: %{
          user_id: ut.user_id,
          balance:
            sum(
              fragment(
                """
                  CASE
                    WHEN ? = 'credit' THEN ?
                    WHEN ? = 'debit' THEN -?
                    WHEN ? = 'charge' THEN ?
                    WHEN ? = 'transfer' THEN -?
                    ELSE ('USD', 0)::money_with_currency
                  END
                """,
                ut.type,
                ut.net_amount,
                ut.type,
                ut.net_amount,
                ut.type,
                ut.net_amount,
                ut.type,
                ut.net_amount
              )
            )
        }

    query =
      from ub in subquery(user_balances),
        join: u in User,
        on: u.id == ub.user_id,
        where: ub.balance != fragment("('USD', 0)::money_with_currency"),
        order_by: [desc: u.type, desc: ub.balance, asc: u.provider_login],
        select: %{
          type: u.type,
          provider_login: u.provider_login,
          balance: ub.balance
        }

    query
    |> Repo.all()
    |> Enum.map(fn
      user ->
        {currency, amount} = user.balance
        %{user | balance: Money.new!(currency, amount)}
    end)
  end
end
