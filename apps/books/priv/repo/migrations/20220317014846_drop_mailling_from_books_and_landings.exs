defmodule Books.Repo.Migrations.DropMaillingFromBooksAndLandings do
  use Ecto.Migration

  def change do
    alter table(:books) do
      remove :mailling_tags
      remove :mailling
    end

    alter table(:landings) do
      remove :tags
    end
  end
end
