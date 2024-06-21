defmodule Books.Repo.Migrations.CreatePostCategories do
  use Ecto.Migration

  def change do
    create table(:post_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :jsonb
      add :color, :string
      timestamps()
    end
  end
end
