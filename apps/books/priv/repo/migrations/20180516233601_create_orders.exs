defmodule Books.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :state, :string
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :remote_ip, :string

      add :accept_tos, :boolean

      add :shipping_address, :string
      add :shipping_postal_code, :string
      add :shipping_city, :string
      add :shipping_state, :string
      add :shipping_country, :string
      add :shipping_amount, :integer

      add :payment_option_id, references(:payment_options, on_delete: :nothing)
      add :payment_id, :string
      add :token, :string
      add :payer_email, :string
      add :payer_first_name, :string
      add :payer_last_name, :string

      timestamps()
    end

    create index(:orders, [:payment_option_id])
  end
end
