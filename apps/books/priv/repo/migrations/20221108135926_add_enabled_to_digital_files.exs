defmodule Books.Repo.Migrations.AddEnabledToDigitalFiles do
  use Ecto.Migration

  def change do
    alter table(:digital_files) do
      add :enabled, :boolean, default: true
    end
  end
end
