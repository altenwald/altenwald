defmodule Books.Repo.Migrations.AddPositionAndCompanyToBookReviews do
  use Ecto.Migration

  def change do
    alter table(:book_reviews) do
      add :position, :string
      add :company, :string
    end
  end
end
