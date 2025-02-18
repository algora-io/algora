defmodule Algora.Stripe.Stub do
  @moduledoc false

  @behaviour Algora.Stripe.Behaviour

  defp random_id(n \\ 1000), do: :rand.uniform(n)

  @impl true
  def create_invoice(_params) do
    {:ok, %Stripe.Invoice{id: "in_#{random_id()}"}}
  end

  @impl true
  def create_invoice_item(_params) do
    {:ok, %Stripe.Invoiceitem{id: "ii_#{random_id()}"}}
  end

  @impl true
  def pay_invoice(invoice_id, _params) do
    {:ok, %Stripe.Invoice{id: invoice_id}}
  end

  @impl true
  def create_transfer(_params) do
    {:ok, %Stripe.Transfer{id: "tr_#{random_id()}"}}
  end

  @impl true
  def create_session(_params) do
    {:ok, %Stripe.Session{id: "cs_#{random_id()}", url: "https://example.com/stripe"}}
  end
end
