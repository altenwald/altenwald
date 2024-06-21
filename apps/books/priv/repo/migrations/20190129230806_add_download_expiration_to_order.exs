defmodule Books.Repo.Migrations.AddDownloadExpirationToOrder do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :download_expires_at, :utc_datetime
    end
  end
end
