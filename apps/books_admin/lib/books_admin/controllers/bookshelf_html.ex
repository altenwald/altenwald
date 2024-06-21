defmodule BooksAdmin.BookshelfHTML do
  use BooksAdmin, :html
  import BooksAdmin.CoverHelpers

  def translate(:purchased), do: gettext("purchased")
  def translate(:external), do: gettext("external")
  def translate(:author), do: gettext("author")

  embed_templates("bookshelf_html/*")
end
