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

  @type metadata :: %{
          optional(String.t()) => String.t()
        }

  @type invoice :: Algora.PSP.Invoice.t()
  defmodule Invoice do
    @moduledoc false
    @type t :: Stripe.Invoice.t()

    @spec create(params, options) :: {:ok, t} | {:error, Algora.PSP.error()}
          when params:
                 %{
                   optional(:auto_advance) => boolean,
                   :metadata => Algora.PSP.metadata(),
                   :customer => Stripe.id() | Stripe.Customer.t()
                 }
                 | %{},
               options: %{
                 :idempotency_key => String.t()
               }
    def create(params, opts), do: Algora.PSP.client(__MODULE__).create(params, Keyword.new(opts))

    @spec pay(Stripe.id() | t, params) :: {:ok, t} | {:error, Algora.PSP.error()}
          when params:
                 %{
                   optional(:off_session) => boolean,
                   optional(:payment_method) => String.t()
                 }
                 | %{}
    def pay(invoice_id, params), do: Algora.PSP.client(__MODULE__).pay(invoice_id, params)

    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
    def retrieve(id, opts), do: Algora.PSP.client(__MODULE__).retrieve(id, Keyword.new(opts))
  end

  @type invoiceitem :: Algora.PSP.Invoiceitem.t()
  defmodule Invoiceitem do
    @moduledoc false
    @type t :: Stripe.Invoiceitem.t()

    @spec create(params, options) :: {:ok, t} | {:error, Algora.PSP.error()}
          when params:
                 %{
                   optional(:amount) => integer,
                   :currency => String.t(),
                   :customer => Stripe.id() | Stripe.Customer.t(),
                   optional(:description) => String.t(),
                   optional(:invoice) => Stripe.id() | Stripe.Invoice.t()
                 }
                 | %{},
               options: %{
                 :idempotency_key => String.t()
               }
    def create(params, opts), do: Algora.PSP.client(__MODULE__).create(params, Keyword.new(opts))
  end

  @type transfer :: Algora.PSP.Transfer.t()
  defmodule Transfer do
    @moduledoc false
    @type t :: Stripe.Transfer.t()

    @spec create(params, options) :: {:ok, t} | {:error, Algora.PSP.error()}
          when params: %{
                 :amount => pos_integer,
                 :currency => String.t(),
                 :destination => String.t(),
                 optional(:metadata) => Algora.PSP.metadata(),
                 optional(:source_transaction) => String.t(),
                 optional(:transfer_group) => String.t(),
                 optional(:description) => String.t(),
                 optional(:source_type) => String.t()
               },
               options: %{
                 :idempotency_key => String.t()
               }
    def create(params, opts), do: Algora.PSP.client(__MODULE__).create(params, Keyword.new(opts))
  end

  @type session :: Algora.PSP.Session.t()
  defmodule Session do
    @moduledoc false

    @type t :: Stripe.Session.t()
    @type line_item_data :: Stripe.Session.line_item_data()
    @type payment_intent_data :: Stripe.Session.payment_intent_data()

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type payment_method :: Algora.PSP.PaymentMethod.t()
  defmodule PaymentMethod do
    @moduledoc false

    @type t :: Stripe.PaymentMethod.t()
    def attach(params), do: Algora.PSP.client(__MODULE__).attach(params)
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
  end

  @type payment_intent :: Algora.PSP.PaymentIntent.t()
  defmodule PaymentIntent do
    @moduledoc false

    @type t :: Stripe.PaymentIntent.t()
    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
    def capture(id, params \\ %{}), do: Algora.PSP.client(__MODULE__).capture(id, params)
  end

  @type setup_intent :: Algora.PSP.SetupIntent.t()
  defmodule SetupIntent do
    @moduledoc false

    @type t :: Stripe.SetupIntent.t()
    def retrieve(id, params), do: Algora.PSP.client(__MODULE__).retrieve(id, params)
  end

  @type customer :: Algora.PSP.Customer.t()
  defmodule Customer do
    @moduledoc false

    @type t :: Stripe.Customer.t()
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type account :: Algora.PSP.Account.t()
  defmodule Account do
    @moduledoc false

    @type t :: Stripe.Account.t()
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
    def delete(id), do: Algora.PSP.client(__MODULE__).delete(id)
  end

  @type account_link :: Algora.PSP.AccountLink.t()
  defmodule AccountLink do
    @moduledoc false

    @type t :: Stripe.AccountLink.t()
    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  @type login_link :: Algora.PSP.LoginLink.t()
  defmodule LoginLink do
    @moduledoc false

    @type t :: Stripe.LoginLink.t()
    def create(id, params \\ %{}), do: Algora.PSP.client(__MODULE__).create(id, params)
  end

  @type balance_transaction :: Algora.PSP.BalanceTransaction.t()
  defmodule BalanceTransaction do
    @moduledoc false

    @type t :: Stripe.BalanceTransaction.t()
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
  end
end
