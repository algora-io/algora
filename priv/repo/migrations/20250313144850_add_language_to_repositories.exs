defmodule Algora.Repo.Migrations.AddLanguageToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :language, :string
    end
  end
end
