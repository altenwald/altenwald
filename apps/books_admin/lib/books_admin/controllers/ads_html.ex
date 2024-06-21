defmodule BooksAdmin.AdsHTML do
  use BooksAdmin, :html
  alias Books.Catalog

  defp get_title(nil), do: gettext("No book")

  defp get_title(book) do
    Catalog.get_full_book_title(book)
  end

  embed_templates("ads_html/*")
end
