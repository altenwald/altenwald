defmodule Books.Repo.Migrations.CreateContents do
  use Ecto.Migration

  def change do
    create table(:contents) do
      add :chapter_type, :string
      add :order, :integer
      add :title, :string
      add :description, :text
      add :excerpt_filename, :string
      add :status, :string
      add :book_id, references(:books, on_delete: :nothing)

      timestamps()
    end

    create index(:contents, [:book_id])
  end
end
