defmodule Algora.Repo.Migrations.MakeGmailIdNullable do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      modify :gmail_id, :string, null: true, from: {:string, null: false}
      modify :message_id, :string, null: true, from: {:string, null: false}
      modify :thread_id, :string, null: true, from: {:string, null: false}
    end
  end
end
