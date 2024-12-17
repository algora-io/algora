defmodule Algora.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query
      @primary_key {:id, :string, autogenerate: false}
      @timestamps_opts [type: :utc_datetime_usec]
      @foreign_key_type :string

      def generate_id(changeset) do
        case get_field(changeset, :id) do
          nil -> put_change(changeset, :id, Nanoid.generate())
          _existing -> changeset
        end
      end
    end
  end
end
