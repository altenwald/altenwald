defmodule Books.Repo.Migrations.AddBundleToLandingPages do
  use Ecto.Migration

  def change do
    alter table(:landings) do
      add :bundle_id, references(:bundles, type: :binary_id, on_delete: :delete_all)
    end

    alter table(:bundles) do
      add :real_price, :integer
      add :price, :integer
    end

    create index(:landings, [:bundle_id])
  end
end
