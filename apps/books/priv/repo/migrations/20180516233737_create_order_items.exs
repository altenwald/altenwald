defmodule Books.Repo.Migrations.CreateOrderItems do
  use Ecto.Migration

  def change do
    create table(:order_items) do
      add :order_id, references(:orders, on_delete: :nothing)
      add :format_id, references(:formats, on_delete: :nothing)
      add :quantity, :integer, default: 1

      timestamps()
    end

    create index(:order_items, [:order_id])
    create index(:order_items, [:format_id])
  end
end
