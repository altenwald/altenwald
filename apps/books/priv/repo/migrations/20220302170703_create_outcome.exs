defmodule Books.Repo.Migrations.CreateOutcome do
  use Ecto.Migration

  def change do
    create table(:outcome, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :month, :integer
      add :year, :integer
      add :items, :integer
      add :amount, :integer
      add :target, :string

      timestamps()
    end
  end
end
