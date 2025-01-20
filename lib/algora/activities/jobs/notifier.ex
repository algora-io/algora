defmodule Algora.Activities.Notifier do
  @moduledoc false
  use Oban.Worker,
    queue: :activity_notifier,
    max_attempts: 1

  alias Algora.Activities

  # unique: [period: 30]

  def changeset(activity, target) do
    case Activities.table_from_schema(target.__meta__.schema) do
      nil ->
        :error

      table when is_atom(table) ->
        new(%{activity_id: activity.id, target_id: target.id, table_name: table})
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    case args do
      %{
        "activity_id" => activity_id,
        "table_name" => table
      }
      when is_binary(table) ->
        activity = Activities.get_with_preloaded_assoc(table, activity_id)
        users_to_notify = Activities.broadcast(activity)
        Activities.notify_users(activity, users_to_notify)
        :ok

      _args ->
        :error
    end
  end
end
