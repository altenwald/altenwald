defmodule Books.Repo.Migrations.AddMaxUsesToOffers do
  use Ecto.Migration

  def change do
    alter table(:offers) do
      add :max_uses, :integer
    end
  end
end
