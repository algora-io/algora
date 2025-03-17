defmodule Algora.Bounties.LineItem do
  @moduledoc false
  use Algora.Schema

  alias Algora.MoneyUtils

  @primary_key false
  typed_embedded_schema do
    field :amount, Algora.Types.Money
    field :title, :string
    field :description, :string
    field :image, :string
    field :type, Ecto.Enum, values: [:payout, :fee]
  end

  def to_stripe(line_item) do
    %{
      price_data: %{
        unit_amount: MoneyUtils.to_minor_units(line_item.amount),
        currency: to_string(line_item.amount.currency),
        product_data:
          Map.reject(
            %{
              name: line_item.title,
              description: line_item.description,
              images: if(line_item.image, do: [line_item.image])
            },
            fn {_, v} -> is_nil(v) end
          )
      },
      quantity: 1
    }
  end

  def to_invoice_item(line_item, invoice, customer) do
    %{
      invoice: invoice.id,
      customer: customer.provider_id,
      amount: MoneyUtils.to_minor_units(line_item.amount),
      currency: to_string(line_item.amount.currency),
      description: if(line_item.description, do: line_item.title <> " - " <> line_item.description, else: line_item.title)
    }
  end

  def gross_amount(line_items) do
    Enum.reduce(line_items, Money.zero(:USD), fn item, acc -> Money.add!(acc, item.amount) end)
  end

  def total_fee(line_items) do
    Enum.reduce(line_items, Money.zero(:USD), fn item, acc ->
      if item.type == :fee, do: Money.add!(acc, item.amount), else: acc
    end)
  end
end
