defmodule Algora.Stripe.Behaviour do
  @callback create_invoice(map()) :: {:ok, map()} | {:error, any()}
  @callback create_invoice_item(map()) :: {:ok, map()} | {:error, any()}
  @callback pay_invoice(String.t(), map()) :: {:ok, map()} | {:error, any()}
end
