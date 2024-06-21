defmodule Books.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def up do
    create table(:roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:roles, [:user_id])
    create unique_index(:roles, [:user_id, :name])

    alter table(:users) do
      remove :admin
    end
  end

  def down do
    alter table(:users) do
      add :admin, :boolean, default: false
    end

    drop table(:roles)
  end
end
