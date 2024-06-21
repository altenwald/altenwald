defmodule Books.Repo.Migrations.CreateDigitalFiles do
  use Ecto.Migration

  def change do
    create table(:digital_files) do
      add :filename, :string
      add :description, :string
      add :filetype, :string
      add :format_id, references(:formats, on_delete: :nothing)

      timestamps()
    end

    create index(:digital_files, [:format_id])
  end
end
