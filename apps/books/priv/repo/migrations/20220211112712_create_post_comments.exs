defmodule Books.Repo.Migrations.CreatePostComments do
  use Ecto.Migration

  def change do
    create table(:post_comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :author_id, references(:authors, type: :binary_id, on_delete: :nilify_all)
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all)
      add :parent_id, references(:post_comments, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end

    create index(:post_comments, [:post_id])
    create index(:post_comments, [:author_id])
  end
end
