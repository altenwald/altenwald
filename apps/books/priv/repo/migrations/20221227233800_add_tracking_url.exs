defmodule Books.Repo.Migrations.AddTrackingUrl do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :shipping_tracking_url, :string
    end
  end
end
