defmodule Books.Repo.Migrations.AddAmazonLinkToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :amazon_link, :string
    end
  end
end
