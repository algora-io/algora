defmodule Algora.Support.StripeMock do
  @moduledoc false

  defmodule Invoice do
    @moduledoc false
    def create(_params) do
      {:ok, %Stripe.Invoice{id: "inv_#{Algora.Util.random_int()}", paid: false, status: "open"}}
    end

    def pay(_invoice_id, %{payment_method: "pm_card_declined"}) do
      {:error,
       %Stripe.Error{
         source: :stripe,
         code: :card_declined,
         message: "Your card was declined"
       }}
    end

    def pay(invoice_id, _params) do
      {:ok, %Stripe.Invoice{id: invoice_id, paid: true, status: "paid"}}
    end
  end

  defmodule Invoiceitem do
    @moduledoc false
    def create(_params) do
      {:ok, %Stripe.Invoiceitem{id: "ii_#{Algora.Util.random_int()}"}}
    end
  end

  defmodule Transfer do
    @moduledoc false

    def create(%{destination: "acct_invalid"}) do
      {:error,
       %Stripe.Error{
         source: :stripe,
         code: :invalid_request_error,
         message: "No such destination: 'acct_invalid'"
       }}
    end

    def create(%{amount: amount, currency: currency, destination: destination}) do
      {:ok,
       %Stripe.Transfer{
         id: "tr_#{Algora.Util.random_int()}",
         amount: amount,
         currency: currency,
         destination: destination
       }}
    end
  end

  defmodule Session do
    @moduledoc false
    def create(_params) do
      {:ok, %Stripe.Session{id: "cs_#{Algora.Util.random_int()}", url: "https://example.com/stripe"}}
    end
  end

  defmodule PaymentMethod do
    @moduledoc false
    def attach(%{payment_method: payment_method_id}) do
      {:ok, %Stripe.PaymentMethod{id: payment_method_id}}
    end
  end

  defmodule SetupIntent do
    @moduledoc false
    def retrieve(id, _params) do
      payment_method_id = "pm_#{:erlang.phash2(id)}"

      {:ok,
       %Stripe.SetupIntent{
         id: "seti_#{:erlang.phash2(id)}",
         payment_method: payment_method_id
       }}
    end
  end
end
