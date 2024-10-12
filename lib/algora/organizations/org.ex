defmodule Algora.Organizations.Org do
  import Ecto.Changeset

  def changeset(org, params) do
    org
    |> cast(params, [
      :handle,
      :name,
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
    |> validate_required([:handle, :name])
  end
end
