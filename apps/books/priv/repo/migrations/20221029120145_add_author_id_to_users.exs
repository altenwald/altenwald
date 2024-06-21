defmodule Books.Repo.Migrations.AddAuthorIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :author_id, references(:authors, type: :binary_id, on_delete: :nilify_all)
    end
  end
end
