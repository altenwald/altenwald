defmodule Books.Repo.Migrations.ChangeAuthorUserRelationship do
  use Ecto.Migration

  def change do
    alter table(:authors) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
    end

    create index(:authors, [:user_id])

    alter table(:users) do
      remove :author_id
    end
  end

  def down do
    alter table(:users) do
      add :author_id, references(:authors, type: :binary_id, on_delete: :delete_all)
    end

    create index(:users, [:author_id])

    alter table(:authors) do
      remove :user_id
    end
  end
end
