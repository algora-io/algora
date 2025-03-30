defmodule Algora.Workspace.Comment do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Workspace.Ticket

  typed_schema "comments" do
    field :body, :string
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map
    field :llm_analyzed_at, :utc_datetime_usec
    field :llm_analysis, :string

    belongs_to :user, User
    belongs_to :ticket, Ticket

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :provider, :provider_id, :provider_meta, :user_id, :ticket_id, :llm_analyzed_at, :llm_analysis])
    |> validate_required([:body, :provider, :provider_id, :provider_meta, :ticket_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:ticket_id)
    |> unique_constraint([:provider, :provider_id])
    |> generate_id()
  end

  def github_changeset(meta, ticket, user \\ nil) do
    params = %{
      provider: "github",
      provider_id: to_string(meta["id"]),
      provider_meta: meta,
      body: meta["body"],
      ticket_id: ticket.id,
      user_id: user && user.id
    }

    changeset(%__MODULE__{}, params)
  end

  def mark_analyzed(comment, analysis \\ nil) do
    changeset(comment, %{
      llm_analyzed_at: DateTime.utc_now(),
      llm_analysis: analysis
    })
  end
end
