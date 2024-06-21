defmodule Books.Repo.Migrations.ChangeAuthorToUserForComments do
  use Ecto.Migration

  def change do
    drop index(:post_comments, [:author_id])

    alter table(:post_comments) do
      remove :author_id
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:post_comments, [:user_id])
  end
end
