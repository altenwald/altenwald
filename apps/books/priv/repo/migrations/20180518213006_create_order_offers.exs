defmodule Books.Repo.Migrations.CreateOrderOffers do
  use Ecto.Migration

  def change do
    create table(:order_offers) do
      add :order_id, references(:orders, on_delete: :nothing)
      add :offer_id, references(:offers, on_delete: :nothing)

      timestamps()
    end

    create index(:order_offers, [:order_id])
    create index(:order_offers, [:offer_id])
  end
end
