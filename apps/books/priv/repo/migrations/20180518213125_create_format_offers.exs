defmodule Books.Repo.Migrations.CreateFormatOffers do
  use Ecto.Migration

  def change do
    create table(:format_offers) do
      add :format_id, references(:formats, on_delete: :nothing)
      add :offer_id, references(:offers, on_delete: :nothing)

      timestamps()
    end

    create index(:format_offers, [:format_id])
    create index(:format_offers, [:offer_id])
  end
end
