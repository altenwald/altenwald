defmodule Books.Repo.Migrations.CreatePostTags do
  use Ecto.Migration

  def change do
    create table(:post_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, type: :binary_id, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:post_tags, [:post_id, :tag_id])
  end
end
