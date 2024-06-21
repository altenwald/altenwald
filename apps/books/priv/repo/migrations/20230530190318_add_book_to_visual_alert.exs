defmodule Books.Repo.Migrations.AddBookToVisualAlert do
  use Ecto.Migration

  def change do
    alter table(:visual_alerts) do
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all)
    end
  end
end
