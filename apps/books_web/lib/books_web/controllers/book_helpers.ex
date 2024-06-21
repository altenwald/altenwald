defmodule BooksWeb.BookHelpers do
  def by_category(books) do
    books
    |> Enum.group_by(& &1.category)
    |> Enum.sort_by(fn {category, _} -> category.name end)
  end
end
