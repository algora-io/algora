defmodule Algora.SQL do
  @moduledoc """
  SQL helper functions and macros for common database operations.
  """

  defmacro money_or_zero(value) do
    quote do
      coalesce(unquote(value), fragment("('USD', 0)::money_with_currency"))
    end
  end

  defmacro sum_by_type(t, type) do
    quote do
      sum(
        fragment(
          "CASE WHEN ? = ? THEN ? ELSE ('USD', 0)::money_with_currency END",
          unquote(t).type,
          unquote(type),
          unquote(t).net_amount
        )
      )
    end
  end
end
