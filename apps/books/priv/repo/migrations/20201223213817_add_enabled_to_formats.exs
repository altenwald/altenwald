defmodule Books.Repo.Migrations.AddEnabledToFormats do
  use Ecto.Migration

  def change do
    alter table(:formats) do
      add :enabled, :boolean
    end
  end
end
