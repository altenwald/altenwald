defmodule Books.Repo.Migrations.CreateBundleContents do
  use Ecto.Migration

  def change do
    create table(:bundle_contents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :order, :integer
      add :title, :string
      add :description, :text
      add :excerpt_filename, :string
      add :bundle_id, references(:bundles, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create index(:bundle_contents, [:bundle_id])
  end
end
