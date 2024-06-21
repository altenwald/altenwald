defmodule Books.Repo.Migrations.SetNotNullForPaymentOptionId do
  use Ecto.Migration

  def change do
    execute("ALTER TABLE orders ALTER payment_option_id DROP NOT NULL")
  end
end
