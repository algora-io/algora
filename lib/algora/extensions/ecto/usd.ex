defmodule Algora.Extensions.Ecto.USD do
  use Ecto.Type

  @impl true
  def type(), do: :money_with_currency

  @impl true
  def cast(string) when is_binary(string) do
    case Money.new(:USD, String.trim(string)) do
      money = %Money{} -> {:ok, money}
      _ -> :error
    end
  end

  def cast(_), do: :error

  @impl true
  def dump(money), do: Money.Ecto.Composite.Type.dump(money)

  @impl true
  def load(money), do: Money.Ecto.Composite.Type.load(money)
end
