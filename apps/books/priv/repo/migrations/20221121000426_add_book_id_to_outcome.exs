defmodule Books.Repo.Migrations.AddBookIdToOutcome do
  use Ecto.Migration

  def change do
    alter table(:outcome) do
      add :book_id, references(:books, type: :uuid)
    end
  end
end
