defmodule BooksAdmin.CatalogController do
  use BooksAdmin, :controller
  alias Books.Catalog

  def index(conn, _params) do
    render(conn, "index.html",
      books: Catalog.list_all_books_with_income(),
      title: gettext("List books")
    )
  end

  defp default_return_to(conn, book_slug \\ nil)

  defp default_return_to(conn, nil) do
    Routes.catalog_path(conn, :index)
  end

  defp default_return_to(conn, book_slug) do
    Routes.catalog_path(conn, :show, book_slug)
  end

  def new(conn, params) do
    book = Catalog.new_book()
    return_to = params["return_to"] || default_return_to(conn)
    render(conn, "new.html", options(book, Catalog.change_book(book), return_to))
  end

  def edit(conn, %{"id" => book_slug} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    return_to = params["return_to"] || default_return_to(conn)
    render(conn, "edit.html", options(book, Catalog.change_book(book), return_to))
  end

  defp options(book, changeset, return_to) do
    [
      book: book,
      changeset: changeset,
      categories: list_categories(),
      languages: list_languages(),
      title:
        case book.id do
          nil -> gettext("New book")
          _ -> gettext("Edit book %{book_slug}", book_slug: book.slug)
        end,
      isbns: list_isbns(),
      return_to: return_to
    ]
  end

  defp list_languages do
    [
      {"", ""},
      {"English", "en"},
      {"Español", "es"}
    ]
  end

  defp list_categories do
    Enum.map(Catalog.list_categories(), &{&1.name, &1.id})
  end

  defp new_value do
    Catalog.new_book_shop_link()
    |> Ecto.embedded_dump(:json)
  end

  defp add_book_shop_link(nil) do
    %{"0" => new_value()}
  end

  defp add_book_shop_link(shop_links) do
    idx =
      shop_links
      |> Map.keys()
      |> Enum.max()
      |> String.to_integer()
      |> then(&(&1 + 1))
      |> to_string()

    Map.put(shop_links, idx, new_value())
  end

  def update(conn, %{"id" => book_slug, "book" => params, "subaction" => "add_shop_link"}) do
    book = Catalog.get_book_by_slug(book_slug)
    return_to = params["return_to"] || default_return_to(conn)
    params = put_in(params["shop_links"], add_book_shop_link(params["shop_links"]))
    render(conn, "edit.html", options(book, Catalog.change_book(book, params), return_to))
  end

  def update(conn, %{
        "id" => book_slug,
        "book" => params,
        "subaction" => "delete_shop_link_" <> idx
      }) do
    book = Catalog.get_book_by_slug(book_slug)
    return_to = params["return_to"] || default_return_to(conn)
    params = put_in(params["shop_links"], Map.delete(params["shop_links"], idx))
    render(conn, "edit.html", options(book, Catalog.change_book(book, params), return_to))
  end

  def update(conn, %{"id" => book_slug, "book" => params} = global_params) do
    if book = Catalog.get_book_by_slug(book_slug) do
      case Catalog.update_book(book, params) do
        {:ok, book} ->
          return_to = global_params["return_to"] || default_return_to(conn, book.slug)

          conn
          |> put_flash(:info, gettext("Book modified successfully"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          return_to = global_params["return_to"] || default_return_to(conn, book.slug)

          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(book, changeset, return_to))
      end
    else
      return_to = global_params["return_to"] || default_return_to(conn)

      conn
      |> put_flash(:error, gettext("Book not found"))
      |> redirect(to: return_to)
    end
  end

  def create(conn, %{"book" => params} = global_params) do
    case Catalog.create_book(params) do
      {:ok, book} ->
        return_to = global_params["return_to"] || default_return_to(conn, book.slug)

        conn
        |> put_flash(:info, gettext("Book created successfully"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        return_to = global_params["return_to"] || default_return_to(conn)
        book = Catalog.new_book()

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("new.html", options(book, changeset, return_to))
    end
  end

  def show(conn, %{"id" => book_slug} = params) do
    book = Catalog.get_book_by_slug(book_slug, true)

    render(conn, "show.html",
      book: book,
      tab_active: params["tab"] || "info",
      title: gettext("Book %{book_slug}", book_slug: book.slug)
    )
  end

  defp list_isbns do
    [{gettext("No ISBN"), ""}] ++
      for isbn <- Catalog.list_isbn() do
        {"#{isbn.isbn} (#{Catalog.get_book_title(isbn.book) || gettext("No assgined")})",
         isbn.isbn}
      end
  end
end
