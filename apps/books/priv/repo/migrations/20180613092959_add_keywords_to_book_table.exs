defmodule Books.Repo.Migrations.AddKeywordsToBookTable do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :keywords, :string
    end
  end
end
