defmodule Algora.Stripe.Impl do
  @moduledoc false

  @behaviour Algora.Stripe.Behaviour

  @impl true
  def create_invoice(params) do
    Stripe.Invoice.create(params)
  end

  @impl true
  def create_invoice_item(params) do
    Stripe.Invoiceitem.create(params)
  end

  @impl true
  def pay_invoice(invoice_id, params) do
    Stripe.Invoice.pay(invoice_id, params)
  end

  @impl true
  def create_transfer(params) do
    Stripe.Transfer.create(params)
  end

  @impl true
  def create_session(params) do
    Stripe.Session.create(params)
  end
end
