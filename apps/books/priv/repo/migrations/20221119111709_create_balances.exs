defmodule Books.Repo.Migrations.CreateBalances do
  use Ecto.Migration
  use Familiar

  def change do
    create_view("balances", version: 1)
  end
end
