defmodule Algora.Organizations.Org do
  use Algora.Schema

  alias Algora.Users.User

  def changeset(org, params) do
    org
    |> cast(params, [
      :handle,
      :domain,
      :bio,
      :avatar_url,
      :location,
      :stargazers_count,
      :tech_stack,
      :featured,
      :priority,
      :fee_pct,
      :seeded,
      :activated,
      :max_open_attempts,
      :manual_assignment,
      :bounty_mode
    ])
    |> generate_id()
    |> validate_required([:type, :handle])
    |> User.validate_handle()
  end
end
