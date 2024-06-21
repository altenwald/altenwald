defmodule Books.Repo.Migrations.CreateIncome do
  use Ecto.Migration

  def change do
    create table(:income, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :book_id, references(:books, type: :uuid)
      add :month, :integer
      add :year, :integer
      add :items, :integer
      add :amount, :integer
      add :source, :string

      timestamps()
    end

    create index(:income, [:book_id])
  end
end
