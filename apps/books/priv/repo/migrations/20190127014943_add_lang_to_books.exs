defmodule Books.Repo.Migrations.AddLangToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :lang, :string
    end
  end
end
