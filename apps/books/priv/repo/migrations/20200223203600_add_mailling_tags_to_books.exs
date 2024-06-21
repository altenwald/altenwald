defmodule Books.Repo.Migrations.AddMaillingTagsToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :mailling_tags, {:array, :string}
    end
  end
end
