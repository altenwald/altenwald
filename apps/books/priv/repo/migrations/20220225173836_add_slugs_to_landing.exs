defmodule Books.Repo.Migrations.AddSlugsToLanding do
  use Ecto.Migration

  def change do
    alter table(:landings) do
      add :slugs, {:array, :string}, default: [], null: false
    end
  end
end
