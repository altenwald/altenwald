defmodule Books.Repo.Migrations.RemCoverFilenameFromBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      remove :image_filename
    end
  end
end
