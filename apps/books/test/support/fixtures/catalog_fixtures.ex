defmodule Books.CatalogFixtures do
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "category",
        color: "color"
      })
      |> Books.Catalog.create_category()

    category
  end

  def author_fixture(attrs \\ %{}) do
    {:ok, author} =
      attrs
      |> Enum.into(%{
        full_name: "Manuel Angel Rubio Jimenez",
        short_name: "Manuel Rubio",
        url: "http://url.com/manuel"
      })
      |> Books.Catalog.create_author()

    author
  end

  def book_fixture(attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> Enum.into(%{
        enabled: true,
        slug: "book-i",
        title: "Book I",
        subtitle: "The Book You Want To Read",
        description: "This is the book you want to read!",
        keywords: "book, wanted",
        marketing_description: "A great book and you want to read it!"
      })
      |> Books.Catalog.create_book()

    book
  end

  def format_fixture(attrs \\ %{}) do
    {:ok, format} =
      attrs
      |> Enum.into(%{
        price: Money.new(10_00)
      })
      |> Books.Catalog.create_format()

    format
  end
end
