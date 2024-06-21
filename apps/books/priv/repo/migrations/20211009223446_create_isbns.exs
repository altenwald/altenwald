defmodule Books.Repo.Migrations.CreateIsbns do
  use Ecto.Migration

  def change do
    create table(:isbns, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tipo_obra, :string
      add :isbn, :string
      add :titulo, :string
      add :status, :string
      add :book_id, references(:books, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end
  end
end
