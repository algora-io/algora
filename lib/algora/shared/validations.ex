defmodule Algora.Validations do
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

  def validate_money_positive(changeset, field) do
    with amount when not is_nil(amount) <- get_change(changeset, field),
         true <- Money.positive?(amount) do
      put_change(changeset, field, amount)
    else
      false -> add_error(changeset, field, "must be positive")
      _ -> changeset
    end
  end

  def validate_ticket_ref(changeset, field, embed_field \\ nil) do
    with url when not is_nil(url) <- get_change(changeset, field),
         {:ok, [ticket_ref: ticket_ref], _, _, _, _} <- Algora.Parser.full_ticket_ref(url) do
      if embed_field do
        put_embed(changeset, embed_field, ticket_ref)
      else
        changeset
      end
    else
      {:error, error, _, _, _, _} -> add_error(changeset, field, error)
      _ -> changeset
    end
  end

  def validate_date_in_future(changeset, field) do
    validate_change(changeset, field, fn _, date ->
      if date && Date.before?(date, DateTime.utc_now()) do
        [{field, "must be in the future"}]
      else
        []
      end
    end)
  end
end
