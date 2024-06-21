defmodule Books.Repo.Migrations.AddEditionToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :edition, :integer, default: 1, null: false
    end
  end
end
