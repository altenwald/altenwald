defmodule BooksWeb.CatalogHTML do
  use BooksWeb, :html

  import BooksWeb.{BookHelpers, CartHelpers}
  import BooksWeb.AuthorComponent

  alias Books.Catalog

  def authors(book, :short_anchor) do
    book.roles
    |> Enum.filter(&(&1.role == :author))
    |> Enum.map_join(", ", &"<a href=\"#author-#{&1.author_id}\">#{&1.author.short_name}</a>")
  end

  def authors(book, :short) do
    book.roles
    |> Enum.filter(&(&1.role == :author))
    |> Enum.map_join(", ", & &1.author.short_name)
  end

  def month({_, 1, _}), do: gettext("January")
  def month({_, 2, _}), do: gettext("February")
  def month({_, 3, _}), do: gettext("March")
  def month({_, 4, _}), do: gettext("April")
  def month({_, 5, _}), do: gettext("May")
  def month({_, 6, _}), do: gettext("June")
  def month({_, 7, _}), do: gettext("July")
  def month({_, 8, _}), do: gettext("August")
  def month({_, 9, _}), do: gettext("September")
  def month({_, 10, _}), do: gettext("October")
  def month({_, 11, _}), do: gettext("November")
  def month({_, 12, _}), do: gettext("December")
  def month(sigil), do: month(Date.to_erl(sigil))

  def year({year, _, _}), do: year
  def year(sigil), do: year(Date.to_erl(sigil))

  def translate_format(:digital), do: gettext("Digital")
  def translate_format(:paper), do: gettext("Paper")
  def translate_format(:presale), do: gettext("Presale")

  def translate_role(:author), do: gettext("Author")
  def translate_role(:editor), do: gettext("Editor")
  def translate_role(:reviewer), do: gettext("Reviewer")
  def translate_role(:translator), do: gettext("Translator")
  def translate_role(:illustrator), do: gettext("Illustrator")

  def translate(:reviewed), do: gettext("reviewed")
  def translate(:prepared), do: gettext("prepared")
  def translate(:todo), do: gettext("to do")
  def translate(:done), do: gettext("final")

  def slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/(\s|-)+/, "-")
  end

  def status_to_tag(:reviewed), do: "tag is-success"
  def status_to_tag(:prepared), do: "tag is-warning"
  def status_to_tag(:todo), do: "tag is-danger"
  def status_to_tag(:done), do: nil

  def kind(%_{name: :digital}, assigns), do: ~H[<i class="fas fa-tablet-alt"></i>]
  def kind(%_{name: :paper}, assigns), do: ~H[<i class="fas fa-book"></i>]
  def kind(%_{name: :presale}, assigns), do: ~H[<i class="fab fa-firstdraft"></i>]

  def get_image(type, book) do
    if String.ends_with?(book.slug, "-#{book.edition}ed") do
      "#{type}-#{book.slug}.png"
    else
      "#{type}-#{book.slug}-#{book.edition}ed.png"
    end
  end

  def edition(%_{edition: 1}), do: gettext("(1st) First edition")
  def edition(%_{edition: 2}), do: gettext("(2nd) Second edition")
  def edition(%_{edition: 3}), do: gettext("(3nd) Third edition")
  def edition(%_{edition: 4}), do: gettext("(4nd) Fourth edition")
  def edition(%_{edition: 5}), do: gettext("(5th) Fifth edition")

  embed_templates "catalog_html/*"
end
