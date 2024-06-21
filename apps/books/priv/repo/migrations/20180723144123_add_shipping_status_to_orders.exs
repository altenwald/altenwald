defmodule Books.Repo.Migrations.AddShippingStatusToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :shipping_status, :string
      add :shipping_status_at, :date
    end
  end
end
