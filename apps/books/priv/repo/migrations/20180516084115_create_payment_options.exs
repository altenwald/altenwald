defmodule Books.Repo.Migrations.CreatePaymentOptions do
  use Ecto.Migration

  def change do
    create table(:payment_options) do
      add :name, :string
      add :slug, :string
      add :amount, :integer

      timestamps()
    end
  end
end
