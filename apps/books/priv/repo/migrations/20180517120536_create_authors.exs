defmodule Books.Repo.Migrations.CreateAuthors do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :full_name, :string
      add :short_name, :string
      add :url, :string

      timestamps()
    end
  end
end
