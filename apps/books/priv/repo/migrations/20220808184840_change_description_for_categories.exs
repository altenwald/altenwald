defmodule Books.Repo.Migrations.ChangeDescriptionForCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      remove :description
      add :description, :jsonb, default: "{}"
    end
  end
end
