defmodule Algora.Forms.FormSubmission do
  @moduledoc false
  use Algora.Schema

  typed_schema "form_submissions" do
    field :form, :string, null: false
    field :email, :string
    field :payload, :map, null: false, default: %{}

    timestamps()
  end

  def changeset(form_submission, attrs) do
    form_submission
    |> cast(attrs, [:form, :email, :payload])
    |> generate_id()
    |> validate_required([:form])
  end
end
