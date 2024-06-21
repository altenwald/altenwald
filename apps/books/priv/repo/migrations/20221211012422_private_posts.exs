defmodule Books.Repo.Migrations.PrivatePosts do
  use Ecto.Migration

  def change do
    create table(:book_posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all), null: false
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:book_posts, [:book_id, :post_id])

    alter table(:posts) do
      add :private, :boolean, default: false, null: false
    end
  end
end
