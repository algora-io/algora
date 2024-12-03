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

  defp impl do
    Application.get_env(:algora, :stripe_impl, Algora.Stripe.Impl)
  end
end
