defmodule Algora.Stripe.Behaviour do
  @moduledoc false
  @callback create_invoice(map()) :: {:ok, map()} | {:error, any()}
  @callback create_invoice_item(map()) :: {:ok, map()} | {:error, any()}
  @callback pay_invoice(String.t(), map()) :: {:ok, map()} | {:error, any()}
  @callback create_transfer(map()) :: {:ok, map()} | {:error, any()}
  @callback create_session(map()) :: {:ok, map()} | {:error, any()}
end
