defmodule Books.Repo.Migrations.AddShippingPhoneToOrder do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :shipping_phone, :string
    end
  end
end
