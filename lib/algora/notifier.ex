defmodule Algora.Notifier do
  @moduledoc false
  def notify_welcome_org(_user, _org) do
    :ok
  end

  def notify_welcome_developer(_user) do
    :ok
  end

  def notify_stripe_account_link_error(_user, _error) do
    :ok
  end
end
