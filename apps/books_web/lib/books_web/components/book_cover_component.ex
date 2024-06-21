defmodule BooksWeb.BookCoverComponent do
  use BooksWeb, :component

  def img(assigns) do
    ~H"""
    <img
      class={assigns[:class] || "book_cover"}
      alt={assigns[:alt] || gettext("book cover")}
      src={img_path(@conn, @book, @size)}
    />
    """
  end

  def img_path(conn, book, size) do
    Routes.static_path(conn, "/images/covers/#{get_image(size, book)}")
  end

  def img_url(conn, book, size) do
    Routes.static_url(conn, "/images/covers/#{get_image(size, book)}")
  end

  defp get_image(type, book) do
    if String.ends_with?(book.slug, "-#{book.edition}ed") do
      "#{type}-#{book.slug}.png"
    else
      "#{type}-#{book.slug}-#{book.edition}ed.png"
    end
  end
end
