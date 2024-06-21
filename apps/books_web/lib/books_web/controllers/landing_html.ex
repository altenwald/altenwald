defmodule BooksWeb.LandingHTML do
  use BooksWeb, :html
  import BooksWeb.MarkdownHelpers

  def get_image(type, book) do
    if String.ends_with?(book.slug, "-#{book.edition}ed") do
      "#{type}-#{book.slug}.png"
    else
      "#{type}-#{book.slug}-#{book.edition}ed.png"
    end
  end

  embed_templates "landing_html/*"
end
