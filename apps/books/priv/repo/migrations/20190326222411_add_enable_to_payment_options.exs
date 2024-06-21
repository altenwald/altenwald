defmodule Books.Repo.Migrations.AddEnableToPaymentOptions do
  use Ecto.Migration

  def change do
    alter table(:payment_options) do
      add :enabled, :boolean
    end
  end
end
