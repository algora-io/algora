defmodule Algora.Repo do
  use Ecto.Repo,
    otp_app: :algora,
    adapter: Ecto.Adapters.Postgres
end
