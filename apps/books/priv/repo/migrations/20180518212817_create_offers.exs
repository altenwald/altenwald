defmodule Books.Repo.Migrations.CreateOffers do
  use Ecto.Migration

  def change do
    create table(:offers) do
      add :name, :string
      add :type, :string
      add :discount_type, :string
      add :discount_amount, :integer
      add :code, :string
      add :expiration, :utc_datetime

      timestamps()
    end
  end
end
