defmodule Books.Repo.Migrations.AddKoboLinkToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :kobo_link, :string
    end
  end
end
