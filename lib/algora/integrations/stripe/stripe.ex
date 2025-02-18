defmodule Algora.Stripe do
  @moduledoc false

  defmodule Invoice do
    @moduledoc false
    @stripe Application.compile_env(:algora, :stripe_impl, Stripe)

    def create(params) do
      @stripe.Invoice.create(params)
    end

    def pay(invoice_id, params) do
      @stripe.Invoice.pay(invoice_id, params)
    end
  end

  defmodule Invoiceitem do
    @moduledoc false
    @stripe Application.compile_env(:algora, :stripe_impl, Stripe)

    def create(params) do
      @stripe.Invoiceitem.create(params)
    end
  end

  defmodule Transfer do
    @moduledoc false
    @stripe Application.compile_env(:algora, :stripe_impl, Stripe)

    def create(params) do
      @stripe.Transfer.create(params)
    end
  end

  defmodule Session do
    @moduledoc false
    @stripe Application.compile_env(:algora, :stripe_impl, Stripe)

    def create(params) do
      @stripe.Session.create(params)
    end
  end
end
