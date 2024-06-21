defmodule Books.Repo.Migrations.CreateFormats do
  use Ecto.Migration

  def change do
    create table(:formats) do
      add :name, :string
      add :price, :integer
      add :tax, :integer
      add :shipping, :boolean
      add :book_id, references(:books, on_delete: :nothing)

      timestamps()
    end

    create index(:formats, [:book_id])
  end
end
