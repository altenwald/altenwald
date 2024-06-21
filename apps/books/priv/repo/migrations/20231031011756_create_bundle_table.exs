defmodule Books.Repo.Migrations.CreateBundleTable do
  use Ecto.Migration

  def change do
    create table(:bundles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :enabled, :boolean, default: false
      add :lang, :string, default: "es"
      add :slug, :string
      add :name, :string
      add :description, :string
      add :keywords, :string
      timestamps()
    end

    create unique_index(:bundles, [:slug])

    create table(:bundle_formats, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :bundle_id, references(:bundles, type: :binary_id, on_delete: :delete_all)
      add :format_id, references(:formats, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end

    create unique_index(:bundle_formats, [:bundle_id, :format_id])
    create index(:bundle_formats, [:bundle_id])
  end
end
