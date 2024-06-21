defmodule Books.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:book_reviews, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :full_name, :string
      add :content, :text
      add :value, :integer
      add :book_id, references(:books, on_delete: :delete_all, type: :binary_id)
      timestamps()
    end

    create index(:book_reviews, [:book_id])
  end
end
