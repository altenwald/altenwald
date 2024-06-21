defmodule Books.Repo.Migrations.AddRoleToBookAuthors do
  use Ecto.Migration

  def change do
    alter table(:book_authors) do
      add :role, :string, default: "author"
    end
  end
end
