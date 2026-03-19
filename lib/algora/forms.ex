defmodule Algora.Forms do
  @moduledoc false

  alias Algora.Forms.FormSubmission
  alias Algora.Repo

  def submit(form, attrs) do
    %FormSubmission{}
    |> FormSubmission.changeset(Map.merge(attrs, %{form: form}))
    |> Repo.insert()
  end
end
