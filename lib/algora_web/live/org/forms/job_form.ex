defmodule AlgoraWeb.Org.Forms.JobForm do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :title, :string
    field :ticket_url, :string
    field :work_type, :string, default: "remote"
    field :min_compensation, :integer
    field :max_compensation, :integer

    embeds_many :projects, Project do
      field :title, :string
      field :url, :string
      field :amount, :integer
    end
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:title, :ticket_url, :work_type, :min_compensation, :max_compensation])
    |> validate_required([:title, :ticket_url, :work_type])
    |> cast_embed(:projects, with: &project_changeset/2)
  end

  defp project_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:title, :url, :amount])
    |> validate_required([:title, :url, :amount])
  end
end
