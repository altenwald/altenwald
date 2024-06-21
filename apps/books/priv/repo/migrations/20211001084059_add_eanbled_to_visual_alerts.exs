defmodule Books.Repo.Migrations.AddEanbledToVisualAlerts do
  use Ecto.Migration

  def change do
    alter table(:visual_alerts) do
      add :enabled, :boolean
    end
  end
end
