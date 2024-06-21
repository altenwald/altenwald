defmodule Books.Repo.Migrations.UpdateBalances do
  use Ecto.Migration
  use Familiar

  def change do
    update_view("balances", version: 2)
  end
end
