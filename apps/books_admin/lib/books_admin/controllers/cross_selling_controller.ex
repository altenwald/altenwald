defmodule BooksAdmin.CrossSellingController do
  use BooksAdmin, :controller
  require Logger
  alias Books.Catalog

  defp default_return_to(conn, book_slug) do
    Routes.catalog_contents_path(conn, :index, book_slug)
  end

  def edit(conn, %{"catalog_id" => book_slug, "id" => id} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    cross_selling = Catalog.get_cross_selling(id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    render(
      conn,
      "edit.html",
      options(book, cross_selling, Catalog.change_cross_selling(cross_selling), return_to)
    )
  end

  def new(conn, %{"catalog_id" => book_slug} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    cross_selling = Catalog.new_cross_selling(book.id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    render(
      conn,
      "new.html",
      options(book, cross_selling, Catalog.change_cross_selling(cross_selling), return_to)
    )
  end

  def update(
        conn,
        %{"catalog_id" => book_slug, "id" => cross_selling_id, "book_cross_selling" => params} =
          global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         params = Map.put(params, "book_id", book.id),
         cross_selling when cross_selling != nil <- Catalog.get_cross_selling(cross_selling_id) do
      changeset = Catalog.change_cross_selling(cross_selling, params)

      case Books.Repo.update(changeset) do
        {:ok, _cross_selling} ->
          conn
          |> put_flash(:info, gettext("Cross selling modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(book, cross_selling, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Cross selling not found"))
        |> redirect(to: return_to)
    end
  end

  def create(conn, %{"catalog_id" => book_slug, "book_cross_selling" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    if book = Catalog.get_book_by_slug(book_slug) do
      cross_selling = Catalog.new_cross_selling(book.id)
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_cross_selling(cross_selling, params)

      case Books.Repo.insert(changeset) do
        {:ok, _cross_selling} ->
          conn
          |> put_flash(:info, gettext("Cross selling created successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("new.html", options(book, cross_selling, changeset, return_to))
      end
    else
      conn
      |> put_flash(:error, gettext("Cross selling not found"))
      |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"catalog_id" => book_slug, "id" => cross_selling_id} = params) do
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         cross_selling when cross_selling != nil <- Catalog.get_cross_selling(cross_selling_id) do
      case Books.Repo.delete(cross_selling) do
        {:ok, _cross_selling} ->
          conn
          |> put_flash(:info, gettext("Cross selling removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{cross_selling_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove cross_selling"))
          |> redirect(to: return_to)
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Cross selling not found"))
        |> redirect(to: return_to)
    end
  end

  defp options(book, cross_selling, changeset, return_to) do
    [
      title:
        case cross_selling do
          %_{id: nil} ->
            gettext("New cross selling for %{slug}", slug: book.slug)

          _ ->
            gettext("Cross selling for %{slug}", slug: book.slug)
        end,
      book: book,
      books: list_books(book.id),
      languages: list_languages(),
      changeset: changeset,
      cross_selling: cross_selling,
      return_to: return_to
    ]
  end

  defp list_languages do
    [
      {gettext("English"), "en"},
      {gettext("Spanish"), "es"}
    ]
  end

  defp list_books(book_id) do
    [{gettext("Choose a book"), ""}] ++
      for book <- Catalog.list_all_books_simple(), book.id != book_id do
        {Catalog.get_full_book_title(book), book.id}
      end
  end
end
