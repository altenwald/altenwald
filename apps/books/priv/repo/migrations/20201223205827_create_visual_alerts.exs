defmodule Books.Repo.Migrations.CreateVisualAlerts do
  use Ecto.Migration

  def change do
    create table(:visual_alerts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :body, :text
      add :type, :string
      add :lang, :string

      timestamps()
    end
  end
end
