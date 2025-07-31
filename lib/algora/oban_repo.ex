defmodule Algora.ObanRepo do
  use Ecto.Repo,
    adapter: Ecto.Adapters.Postgres,
    otp_app: :algora
end