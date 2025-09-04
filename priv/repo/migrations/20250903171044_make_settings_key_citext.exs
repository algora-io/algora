defmodule Algora.Repo.Migrations.MakeSettingsKeyCitext do
  use Ecto.Migration

  def change do
    alter table(:settings) do
      modify :key, :citext
    end
  end
end
