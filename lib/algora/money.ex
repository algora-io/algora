defmodule Algora.Money do
  alias Money, as: M

  def format(amount, currency) do
    M.new(amount, currency) |> M.to_string(no_fraction_if_integer: true)
  end

  def format!(amount, currency) do
    {:ok, res} = format(amount, currency)
    res
  end
end
