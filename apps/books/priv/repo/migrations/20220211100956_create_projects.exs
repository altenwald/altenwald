defmodule Books.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :description, :text
      add :logo, :string
      add :name, :string
      add :url, :string
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:projects, [:book_id])
  end
end
