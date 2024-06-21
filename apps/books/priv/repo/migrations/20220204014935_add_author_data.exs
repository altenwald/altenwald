defmodule Books.Repo.Migrations.AddAuthorData do
  use Ecto.Migration

  def change do
    alter table(:authors) do
      add :title, :jsonb
      add :description, :jsonb
    end
  end
end
