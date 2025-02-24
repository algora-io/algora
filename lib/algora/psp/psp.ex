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

  defmodule Invoice do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
    def pay(invoice_id, params), do: Algora.PSP.client(__MODULE__).pay(invoice_id, params)
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
    def retrieve(id, opts), do: Algora.PSP.client(__MODULE__).retrieve(id, opts)
  end

  defmodule Invoiceitem do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  defmodule Transfer do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  defmodule Session do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  defmodule PaymentMethod do
    @moduledoc false

    def attach(params), do: Algora.PSP.client(__MODULE__).attach(params)
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
  end

  defmodule PaymentIntent do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  defmodule SetupIntent do
    @moduledoc false

    def retrieve(id, params), do: Algora.PSP.client(__MODULE__).retrieve(id, params)
  end

  defmodule Customer do
    @moduledoc false

    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  defmodule Account do
    @moduledoc false

    # TODO: remove empty array if dialyzer doesnt complain
    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id, [])
    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
    def delete(id), do: Algora.PSP.client(__MODULE__).delete(id)
  end

  defmodule AccountLink do
    @moduledoc false

    def create(params), do: Algora.PSP.client(__MODULE__).create(params)
  end

  defmodule LoginLink do
    @moduledoc false

    # TODO: remove empty map if dialyzer doesnt complain
    def create(params), do: Algora.PSP.client(__MODULE__).create(params, %{})
  end

  defmodule BalanceTransaction do
    @moduledoc false

    def retrieve(id), do: Algora.PSP.client(__MODULE__).retrieve(id)
  end
end
