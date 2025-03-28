defmodule AlgoraWeb.API.ErrorJSON do
  @doc """
  Renders changeset errors.
  """
  def error(%{changeset: changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    }
  end

  @doc """
  Renders error message.
  """
  def error(%{message: message}) do
    %{error: message}
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn
      {key, value}, acc when is_binary(value) ->
        String.replace(acc, "%{#{key}}", value)

      {key, value}, acc when is_integer(value) ->
        String.replace(acc, "%{#{key}}", Integer.to_string(value))

      {key, value}, acc ->
        String.replace(acc, "%{#{key}}", inspect(value))
    end)
  end
end
