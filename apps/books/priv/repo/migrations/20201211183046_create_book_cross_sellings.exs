defmodule Books.Repo.Migrations.CreateBookCrossSellings do
  use Ecto.Migration

  def change do
    create table(:book_cross_sellings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :description, :text
      add :lang, :string
      add :book_id, references(:books, type: :uuid, on_delete: :delete_all)
      add :book_crossed_id, references(:books, type: :uuid, on_delete: :delete_all)

      timestamps()
    end

    create index(:book_cross_sellings, [:book_id])
    create index(:book_cross_sellings, [:book_crossed_id])
  end
end
