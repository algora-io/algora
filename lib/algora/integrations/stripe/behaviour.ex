defmodule Algora.Stripe.Behaviour do
  @moduledoc false
  @callback create_invoice(map()) :: {:ok, Stripe.Invoice.t()} | {:error, Stripe.Error.t()}
  @callback create_invoice_item(map()) :: {:ok, Stripe.Invoiceitem.t()} | {:error, Stripe.Error.t()}
  @callback pay_invoice(Stripe.id() | Stripe.Invoice.t(), map()) :: {:ok, Stripe.Invoice.t()} | {:error, Stripe.Error.t()}
  @callback create_transfer(map()) :: {:ok, Stripe.Transfer.t()} | {:error, Stripe.Error.t()}
  @callback create_session(map()) :: {:ok, Stripe.Session.t()} | {:error, Stripe.Error.t()}
end
