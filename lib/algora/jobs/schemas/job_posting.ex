defmodule Algora.Jobs.JobPosting do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User

  typed_schema "job_postings" do
    field :title, :string
    field :description, :string
    field :tech_stack, {:array, :string}, default: []
    field :url, :string
    field :company_name, :string
    field :company_url, :string
    field :email, :string
    field :status, Ecto.Enum, values: [:initialized, :processing, :active, :expired], null: false, default: :initialized
    field :expires_at, :utc_datetime_usec
    # e.g. "SF Bay Area (Remote)"
    field :location, :string
    # e.g. ["US", "CA", "BR"]
    field :countries, {:array, :string}, default: []
    # e.g. ["LATAM", "NA"]
    field :regions, {:array, :string}, default: []
    field :compensation, :string
    field :seniority, :string

    belongs_to :user, User, null: false

    timestamps()
  end

  def changeset(job_posting, attrs) do
    job_posting
    |> cast(attrs, [
      :title,
      :description,
      :tech_stack,
      :url,
      :company_name,
      :company_url,
      :email,
      :status,
      :expires_at,
      :user_id,
      :location,
      :compensation,
      :seniority,
      :countries,
      :regions
    ])
    |> generate_id()
    |> validate_required([:url, :company_name, :company_url, :email])
    |> User.validate_email()
    |> foreign_key_constraint(:user)
  end
end
