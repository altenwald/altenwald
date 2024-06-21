defmodule Books.Repo.Migrations.Uuid do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

    change_id("authors", "author_id")
    |> change_relation("book_authors")
    |> change_id_end()

    change_id("books", "book_id")
    |> change_relation("book_authors")
    |> change_relation("contents")
    |> change_relation("formats")
    |> change_id_end()

    change_id("formats", "format_id")
    |> change_relation("digital_files")
    |> change_relation("format_offers")
    |> change_relation("offer_applies")
    |> change_relation("order_items")
    |> change_id_end()

    change_id("offers", "offer_id")
    |> change_relation("format_offers")
    |> change_relation("offer_applies")
    |> change_relation("order_offers")
    |> change_id_end()

    change_id("orders", "order_id")
    |> change_relation("order_items")
    |> change_relation("order_offers")
    |> change_id_end()

    change_id("payment_options", "payment_option_id")
    |> change_relation("orders")
    |> change_id_end()

    [
      "order_items",
      "contents",
      "digital_files",
      "order_items",
      "book_authors",
      "order_offers",
      "format_offers",
      "offer_applies"
    ]
    |> Enum.each(&change_id_alone(&1))
  end

  defp change_relation({primary_table, foreign_key}, foreign_table) do
    execute "ALTER TABLE #{foreign_table} RENAME #{foreign_key} TO old_#{foreign_key}"
    execute "ALTER TABLE #{foreign_table} ADD #{foreign_key} UUID REFERENCES #{primary_table}(id)"

    execute "UPDATE #{foreign_table} ft SET #{foreign_key} = (SELECT id FROM #{primary_table} WHERE old_id = ft.old_#{foreign_key})"

    execute "ALTER TABLE #{foreign_table} DROP old_#{foreign_key}"
    execute "ALTER TABLE #{foreign_table} ALTER #{foreign_key} SET NOT NULL"
    {primary_table, foreign_key}
  end

  defp change_id(table, foreign_key \\ "") do
    execute "ALTER TABLE #{table} RENAME id TO old_id"
    execute "ALTER TABLE #{table} ADD id UUID DEFAULT gen_random_uuid()"
    execute "CREATE UNIQUE INDEX ON #{table}(id)"
    {table, foreign_key}
  end

  defp change_id_end({table, _}) do
    execute "ALTER TABLE #{table} DROP old_id"
    execute "ALTER TABLE #{table} ADD PRIMARY KEY(id)"
    nil
  end

  defp change_id_alone(table), do: change_id_end(change_id(table))
end
