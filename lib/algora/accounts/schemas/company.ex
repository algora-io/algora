defmodule Algora.Accounts.Company do
  @moduledoc false
  use Algora.Schema

  typed_schema "companies" do
    field :name, :string
    field :logo_url, :string
    field :linkedin_id, :string
    timestamps()
  end

  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :logo_url, :linkedin_id])
    |> validate_required([:name])
    |> generate_id()
    |> unique_constraint(:name)
  end
end
