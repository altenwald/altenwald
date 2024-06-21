defmodule Books.Repo.Migrations.AddLanguageToLandingPages do
  use Ecto.Migration

  def change do
    alter table(:landings) do
      add :lang, :string, default: "es"
    end
  end
end
