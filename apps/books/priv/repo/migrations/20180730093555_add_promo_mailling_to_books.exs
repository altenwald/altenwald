defmodule Books.Repo.Migrations.AddPromoMaillingToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :promo_mailling, :string
    end
  end
end
