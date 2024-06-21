defmodule Books.Repo.Migrations.ChangeCarouselForBundle do
  use Ecto.Migration

  def change do
    alter table(:ads_carousel) do
      add :type, :string, default: "book"
      add :bundle_id, references(:bundles, type: :binary_id, on_delete: :delete_all)
    end

    create index(:ads_carousel, [:bundle_id])
  end
end
