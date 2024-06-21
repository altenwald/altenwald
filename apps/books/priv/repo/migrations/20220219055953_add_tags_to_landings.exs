defmodule Books.Repo.Migrations.AddTagsToLandings do
  use Ecto.Migration

  def change do
    alter table(:landings) do
      add :tags, {:array, :string}, default: [], null: false
    end
  end
end
