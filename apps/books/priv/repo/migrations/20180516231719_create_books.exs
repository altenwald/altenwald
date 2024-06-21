defmodule Books.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :slug, :string, unique: true
      add :title, :string
      add :subtitle, :string
      add :description, :text
      add :marketing_description, :text
      add :image_filename, :string
      add :resources_url, :string

      add :enabled, :boolean
      add :presale, :date
      add :release, :date

      add :num_pages, :integer
      add :isbn, :string
      add :legal_deposit, :string

      add :mailling, :string

      timestamps()
    end
  end
end
