defmodule Books.Repo.Migrations.RemovePromoMailling do
  use Ecto.Migration

  def change do
    alter table(:books) do
      remove :promo_mailling
    end
  end
end
