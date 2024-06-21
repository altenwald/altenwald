defmodule Books.Repo.Migrations.AddPrevewPagesToLandings do
  use Ecto.Migration

  def change do
    alter table(:landings) do
      add :preview_pages, :integer, default: 0
    end
  end
end
