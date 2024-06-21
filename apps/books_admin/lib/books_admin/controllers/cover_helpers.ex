defmodule BooksAdmin.CoverHelpers do
  import BooksAdmin.Router.Helpers

  def get_cover_path(conn, book) do
    static_path(conn, "/images/covers/#{get_image(:small, book)}")
  end

  def get_image(type, book) do
    if String.ends_with?(book.slug, "-#{book.edition}ed") do
      "#{type}-#{book.slug}.png"
    else
      "#{type}-#{book.slug}-#{book.edition}ed.png"
    end
  end
end
