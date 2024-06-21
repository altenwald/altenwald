defmodule BooksWeb.UserBookshelfHTML do
  use BooksWeb, :html

  defp short_text(text, length) when byte_size(text) <= length, do: text

  defp short_text(text, length) do
    String.slice(text, 0..(length - 4)) <> "..."
  end

  defdelegate get_image(type, book), to: BooksWeb.CatalogHTML

  embed_templates "user_bookshelf_html/*"
end
