defmodule Algora.Types.Money do
  @moduledoc false

  use Ecto.ParameterizedType

  alias Money.Ecto.Composite.Type

  @type t :: Money.t()

  defdelegate type(params), to: Type
  defdelegate cast_type(opts), to: Type
  defdelegate load(tuple, loader, params), to: Type
  defdelegate dump(money, dumper, params), to: Type
  defdelegate cast(money), to: Type
  defdelegate cast(money, params), to: Type
  defdelegate embed_as(term), to: Type
  defdelegate embed_as(term, params), to: Type
  defdelegate equal?(money1, money2), to: Type

  def init(opts) do
    opts
    |> Type.init()
    |> Keyword.put(:no_fraction_if_integer, true)
  end
end
