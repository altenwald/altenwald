defmodule Books.Repo.Migrations.AddExteranlLinksForBooks do
  use Ecto.Migration

  def up do
    alter table(:books) do
      add :shop_links, :jsonb, default: "[]"
    end

    alter table(:books) do
      remove :amazon_link
      remove :gplay_link
      remove :kobo_link
    end
  end

  def down do
    alter table(:books) do
      add :amazon_link, :string
      add :gplay_link, :string
      add :kobo_link, :string
    end

    alter table(:books) do
      remove :shop_links
    end
  end
end
