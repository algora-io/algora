defmodule Algora.Signal do
  @moduledoc false
  @provider Appsignal

  defdelegate send_error(exception, stacktrace), to: @provider
  defdelegate send_error(kind, reason, stacktrace), to: @provider

  def send_stripe_error(%Stripe.Error{} = error, exception, stacktrace \\ nil) do
    case error do
      %{extra: %{raw_error: %{"message" => message}}} ->
        send_error(%{exception | message: message}, stacktrace)

      _error ->
        send_error(%{exception | message: "Unknown Stripe error"}, stacktrace)
    end
  end
end
