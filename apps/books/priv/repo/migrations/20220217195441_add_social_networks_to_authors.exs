defmodule Books.Repo.Migrations.AddSocialNetworksToAuthors do
  use Ecto.Migration

  def change do
    alter table(:authors) do
      add :social_networks, :jsonb, default: "{}"
    end
  end
end
