defmodule Books.Repo.Migrations.AddCategoryToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :category_id, references(:categories, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:books, [:category_id])
  end
end
