defmodule Books.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      timestamps()
    end

    create unique_index(:tags, [:name])
  end
end
