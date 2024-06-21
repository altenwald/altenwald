defmodule BooksAdmin.BookAuthorsController do
  use BooksAdmin, :controller
  require Logger
  alias Books.Catalog

  defp default_return_to(conn, book_slug) do
    Routes.catalog_path(conn, :show, book_slug)
  end

  def edit(conn, %{"catalog_id" => book_slug, "id" => id} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    book_author = Catalog.get_book_author(id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    render(
      conn,
      "edit.html",
      options(book, book_author, Catalog.change_book_author(book_author), return_to)
    )
  end

  def new(conn, %{"catalog_id" => book_slug} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    book_author = Catalog.new_book_author(book.id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    render(
      conn,
      "new.html",
      options(book, book_author, Catalog.change_book_author(book_author), return_to)
    )
  end

  def update(
        conn,
        %{"catalog_id" => book_slug, "id" => book_author_id, "book_author" => params} =
          global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         book_author when book_author != nil <- Catalog.get_book_author(book_author_id) do
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_book_author(book_author, params)

      case Books.Repo.update(changeset) do
        {:ok, _book_author} ->
          conn
          |> put_flash(:info, gettext("Book role modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(book, book_author, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Book role not found"))
        |> redirect(to: return_to)
    end
  end

  def create(conn, %{"catalog_id" => book_slug, "book_author" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    if book = Catalog.get_book_by_slug(book_slug) do
      book_author = Catalog.new_book_author(book.id)
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_book_author(book_author, params)

      case Books.Repo.insert(changeset) do
        {:ok, _book_author} ->
          conn
          |> put_flash(:info, gettext("Book role created successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("new.html", options(book, book_author, changeset, return_to))
      end
    else
      conn
      |> put_flash(:error, gettext("Book role not found"))
      |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"catalog_id" => book_slug, "id" => book_author_id} = params) do
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         book_author when book_author != nil <- Catalog.get_book_author(book_author_id) do
      case Books.Repo.delete(book_author) do
        {:ok, _book_author} ->
          conn
          |> put_flash(:info, gettext("Book role removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{book_author_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove book role"))
          |> redirect(to: return_to)
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Book role not found"))
        |> redirect(to: return_to)
    end
  end

  defp options(book, book_author, changeset, return_to) do
    [
      title:
        case book_author do
          %_{id: nil} ->
            gettext("New book role from %{slug}", slug: book.slug)

          _ ->
            gettext("Book role for %{slug}", slug: book.slug)
        end,
      book: book,
      changeset: changeset,
      book_author: book_author,
      roles: list_roles(),
      authors: list_authors(),
      return_to: return_to
    ]
  end

  defp list_roles do
    [
      {gettext("Choose one..."), ""},
      {gettext("Author"), "author"},
      {gettext("Reviewer"), "reviewer"},
      {gettext("Translator"), "translator"},
      {gettext("Editor"), "editor"},
      {gettext("Illustrator"), "illustrator"}
    ]
  end

  defp list_authors do
    [{gettext("Choose one..."), ""}] ++
      for author <- Catalog.list_authors() do
        {author.short_name, author.id}
      end
  end
end
