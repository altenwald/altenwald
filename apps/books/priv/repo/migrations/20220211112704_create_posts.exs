defmodule Books.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :lang, :string, null: false
      add :slug, :string, null: false
      add :title, :string, null: false
      add :subtitle, :string
      add :featured_image, :string
      add :background_image, :string
      add :excerpt, :text
      add :content, :text, null: false
      add :category_id, references(:post_categories, type: :binary_id, on_delete: :nilify_all)
      add :author_id, references(:authors, type: :binary_id, on_delete: :nilify_all)
      timestamps()
    end

    create index(:posts, [:category_id])
    create index(:posts, [:author_id])
    create unique_index(:posts, [:slug])
    create index(:posts, [:inserted_at])
    create index(:posts, [:lang])
  end
end
