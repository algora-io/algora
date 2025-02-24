defmodule Algora.PSP do
  @moduledoc """
  Payment Service Provider (PSP) interface module.

  This module serves as an abstraction layer for payment service provider interactions.
  Currently, it implements Stripe as the default payment processor, but is designed
  to be extensible for supporting multiple payment providers in the future (e.g., PayPal).

  The module provides a unified interface for common payment operations such as:
  - Invoice management
  - Payment processing
  - Transfer operations
  - Checkout sessions
  - Payment method handling
  - Setup intents

  Each submodule corresponds to a specific payment service functionality and delegates
  to the configured payment provider client (currently Stripe).
  """

  def client(module) do
    :algora
    |> Application.get_env(:stripe_client, Stripe)
    |> Module.concat(module |> Module.split() |> List.last())
  end

  @type error :: Stripe.Error.t()

  @type invoice :: Stripe.Invoice.t()
  defmodule Invoice do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
    def pay(invoice_id, params), do: Algora.PSP.client(__MODULE__).pay(invoice_id, params)
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
    def retrieve(id, opts), do: Algora.PSP.client(__MODULE__).retrieve(id, opts)
  end

  @type invoiceitem :: Stripe.Invoiceitem.t()
  defmodule Invoiceitem do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type transfer :: Stripe.Transfer.t()
  defmodule Transfer do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type session :: Stripe.Session.t()
  defmodule Session do
    @moduledoc false

    @type line_item_data :: Stripe.Session.line_item_data()
    @type payment_intent_data :: Stripe.Session.payment_intent_data()

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type payment_method :: Stripe.PaymentMethod.t()
  defmodule PaymentMethod do
    @moduledoc false

    def attach(params), do: Algora.PSP.client(__MODULE__).attach(params)
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
  end

  @type payment_intent :: Stripe.PaymentIntent.t()
  defmodule PaymentIntent do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type setup_intent :: Stripe.SetupIntent.t()
  defmodule SetupIntent do
    @moduledoc false

    def retrieve(id, params), do: Algora.PSP.client(__MODULE__).retrieve(id, params)
  end

  @type customer :: Stripe.Customer.t()
  defmodule Customer do
    @moduledoc false

    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type account :: Stripe.Account.t()
  defmodule Account do
    @moduledoc false

    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
    def delete(id), do: Algora.PSP.client(__MODULE__).delete(id)
  end

  @type account_link :: Stripe.AccountLink.t()
  defmodule AccountLink do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type login_link :: Stripe.LoginLink.t()
  defmodule LoginLink do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type balance_transaction :: Stripe.BalanceTransaction.t()
  defmodule BalanceTransaction do
    @moduledoc false

    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
  end
end
