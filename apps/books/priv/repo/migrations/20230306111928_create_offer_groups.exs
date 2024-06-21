defmodule Books.Repo.Migrations.CreateOfferGroups do
  use Ecto.Migration

  def change do
    create table(:offer_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      timestamps()
    end

    create unique_index(:offer_groups, [:name])

    alter table(:offers) do
      add :offer_group_id, references(:offer_groups, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:offers, [:offer_group_id])
  end
end
