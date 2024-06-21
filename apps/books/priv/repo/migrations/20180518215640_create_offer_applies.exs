defmodule Books.Repo.Migrations.CreateOfferApplies do
  use Ecto.Migration

  def change do
    create table(:offer_applies) do
      add :format_id, references(:formats, on_delete: :nothing)
      add :offer_id, references(:offers, on_delete: :nothing)

      timestamps()
    end

    create index(:offer_applies, [:format_id])
    create index(:offer_applies, [:offer_id])
  end
end
