defmodule Algora.Types.USD do
  @moduledoc false
  use Ecto.Type

  alias Money.Ecto.Composite.Type

  @impl true
  def type, do: :money_with_currency

  @impl true
  def cast(string) when is_binary(string) do
    string = string |> String.replace("$", "") |> String.trim()

    case Money.new(:USD, string) do
      %Money{} = money -> {:ok, money}
      {:error, _reason} -> :error
    end
  end

  def cast(_), do: :error

  @impl true
  def dump(money), do: Type.dump(money)

  @impl true
  def load(money), do: Type.load(money)
end
