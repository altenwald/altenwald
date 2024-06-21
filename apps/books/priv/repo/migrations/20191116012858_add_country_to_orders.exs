defmodule Books.Repo.Migrations.AddCountryToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :country, :string
    end
  end
end
