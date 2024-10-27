defmodule Algora.Money do
  alias Money, as: M

  def format(amount, currency, opts \\ []) do
    default_opts = [no_fraction_if_integer: true]
    merged_opts = Keyword.merge(default_opts, opts)
    M.new(amount, currency) |> M.to_string(merged_opts)
  end

  def format!(amount, currency, opts \\ []) do
    {:ok, res} = format(amount, currency, opts)
    res
  end
end
