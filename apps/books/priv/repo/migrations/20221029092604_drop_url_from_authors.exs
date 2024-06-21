defmodule Books.Repo.Migrations.DropUrlFromAuthors do
  use Ecto.Migration

  def change do
    rename table(:authors), :social_networks, to: :urls

    alter table(:authors) do
      remove :url
    end
  end
end
