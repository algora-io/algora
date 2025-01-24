defmodule Algora.Signal do
  @moduledoc false
  @provider Appsignal

  def send_error(%Ecto.Changeset{} = error, exception) do
    send_error(error, exception, [])
  end

  def send_error(%Stripe.Error{} = error, exception) do
    send_error(error, exception, [])
  end

  def send_error(%Stripe.Error{} = error, exception, stacktrace) do
    case error do
      %{extra: %{raw_error: %{"message" => message}}} ->
        send_error(%{exception | message: message}, stacktrace)

      _error ->
        send_error(%{exception | message: "Unknown Stripe error"}, stacktrace)
    end

    :ok
  end

  defdelegate send_error(exception, stacktrace), to: @provider
  defdelegate send_error(kind, reason, stacktrace), to: @provider
end
