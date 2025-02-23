defmodule Algora.Stripe do
  @moduledoc false

  def client(module) do
    :algora
    |> Application.get_env(:stripe_client, Stripe)
    |> Module.concat(module |> Module.split() |> List.last())
  end

  defmodule Invoice do
    @moduledoc false

    def create(params), do: Algora.Stripe.client(__MODULE__).create(params)

    def pay(invoice_id, params), do: Algora.Stripe.client(__MODULE__).pay(invoice_id, params)
  end

  defmodule Invoiceitem do
    @moduledoc false

    def create(params), do: Algora.Stripe.client(__MODULE__).create(params)
  end

  defmodule Transfer do
    @moduledoc false

    def create(params), do: Algora.Stripe.client(__MODULE__).create(params)
  end

  defmodule Session do
    @moduledoc false

    def create(params), do: Algora.Stripe.client(__MODULE__).create(params)
  end

  defmodule PaymentMethod do
    @moduledoc false

    def attach(params), do: Algora.Stripe.client(__MODULE__).attach(params)
  end

  defmodule SetupIntent do
    @moduledoc false

    def retrieve(id, params), do: Algora.Stripe.client(__MODULE__).retrieve(id, params)
  end
end
