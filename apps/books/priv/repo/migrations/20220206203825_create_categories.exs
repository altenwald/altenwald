defmodule Books.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :color, :string, null: false
      add :description, :text
      timestamps()
    end

    create unique_index(:categories, [:name])
  end
end
