defmodule Algora.StripeUtils do
  def field_to_id(nil), do: nil
  def field_to_id(field) when is_binary(field), do: field
  def field_to_id(field), do: field.id

  def field_to_entity(nil, _), do: {:error, :not_found}
  def field_to_entity(field, func) when is_binary(field), do: func.(field)
  def field_to_entity(field, _), do: {:ok, field}
end
