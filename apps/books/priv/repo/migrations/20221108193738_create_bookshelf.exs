defmodule Books.Repo.Migrations.CreateBookshelf do
  use Ecto.Migration

  def change do
    create table(:bookshelf_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :description, :string
      add :started_at, :date
      add :expires_at, :date
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all), null: false
      add :order_id, references(:orders, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create index(:bookshelf_items, [:user_id])
    create index(:bookshelf_items, [:book_id])
    create index(:bookshelf_items, [:order_id])
    create unique_index(:bookshelf_items, [:user_id, :book_id])
  end
end
