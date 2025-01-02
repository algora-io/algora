defmodule Algora.Stripe do
  @moduledoc false

  @behaviour Algora.Stripe.Behaviour

  @impl true
  def create_invoice(params) do
    impl().create_invoice(params)
  end

  @impl true
  def create_invoice_item(params) do
    impl().create_invoice_item(params)
  end

  @impl true
  def pay_invoice(invoice_id, params) do
    impl().pay_invoice(invoice_id, params)
  end

  @impl true
  def create_transfer(params) do
    impl().create_transfer(params)
  end

  def field_to_id(nil), do: nil
  def field_to_id(field) when is_binary(field), do: field
  def field_to_id(field), do: field.id

  def field_to_entity(nil, _), do: {:error, :not_found}
  def field_to_entity(field, func) when is_binary(field), do: func.(field)
  def field_to_entity(field, _), do: {:ok, field}

  defp impl do
    Application.get_env(:algora, :stripe_impl, Algora.Stripe.Impl)
  end
end
