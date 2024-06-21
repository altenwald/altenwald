defmodule Books.Repo.Migrations.AddLangAndTagsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :lang, :string, size: 2, default: "es", null: false
      add :mailling_tags, {:array, :string}, default: [], null: false
    end
  end
end
