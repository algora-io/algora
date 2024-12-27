defmodule Algora.Extensions.Ecto.USD do
  use Ecto.Type

  @impl true
  def type(), do: :money_with_currency

  @impl true
  def cast(string) when is_binary(string) do
    string = string |> String.replace("$", "") |> String.trim()

    case Money.new(:USD, string) do
      money = %Money{} -> {:ok, money}
      {:error, _reason} -> :error
    end
  end

  def cast(_), do: :error

  @impl true
  def dump(money), do: Money.Ecto.Composite.Type.dump(money)

  @impl true
  def load(money), do: Money.Ecto.Composite.Type.load(money)
end
