defmodule Books.Repo.Migrations.CreateAdsCarousel do
  use Ecto.Migration

  def change do
    create table(:ads_carousel, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :image, :string
      add :priority, :integer
      add :enable, :boolean, default: false, null: false
      add :book_id, references(:books, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:ads_carousel, [:book_id])
  end
end
