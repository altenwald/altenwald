defmodule Books.Repo.Migrations.AddGplayLinkToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :gplay_link, :string
    end
  end
end
