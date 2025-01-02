defmodule Algora.Validators do
  @moduledoc false
  import Ecto.Changeset

  def validate_greater_than(changeset, field, value) do
    validate_change(changeset, field, fn _, field_value ->
      if Money.compare(field_value, value) == :gt do
        []
      else
        [{field, "must be greater than #{Money.to_string!(value)}"}]
      end
    end)
  end

  def validate_positive(changeset, field) do
    validate_greater_than(changeset, field, Money.zero(:USD))
  end
end
