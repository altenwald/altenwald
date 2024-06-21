defmodule BooksAdmin.FormatsController do
  use BooksAdmin, :controller
  require Logger
  alias Books.Catalog

  defp default_return_to(conn, book_slug) do
    Routes.catalog_path(conn, :show, book_slug)
  end

  def edit(conn, %{"catalog_id" => book_slug, "id" => id} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    format = Catalog.get_format(id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)
    render(conn, "edit.html", options(book, format, Catalog.change_format(format), return_to))
  end

  def new(conn, %{"catalog_id" => book_slug} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    format = Catalog.new_format(book.id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)
    render(conn, "new.html", options(book, format, Catalog.change_format(format), return_to))
  end

  defp list_format_types do
    [
      {gettext("Presale"), "presale"},
      {gettext("Digital"), "digital"},
      {gettext("Paper"), "paper"}
    ]
  end

  defp options(book, format, changeset, return_to) do
    [
      title:
        case format do
          %_{id: nil} ->
            gettext("New format from %{slug}", slug: book.slug)

          _ ->
            gettext("Format from %{slug}", slug: book.slug)
        end,
      book: book,
      changeset: changeset,
      format: format,
      format_types: list_format_types(),
      return_to: return_to
    ]
  end

  def update(
        conn,
        %{"catalog_id" => book_slug, "id" => format_id, "format" => params} = global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         format when format != nil <- Catalog.get_format(format_id) do
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_format(format, params)

      case Books.Repo.update(changeset) do
        {:ok, _format} ->
          conn
          |> put_flash(:info, gettext("Format modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(book, format, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Format not found"))
        |> redirect(to: return_to)
    end
  end

  def create(conn, %{"catalog_id" => book_slug, "format" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    if book = Catalog.get_book_by_slug(book_slug) do
      format = Catalog.new_format(book.id)
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_format(format, params)

      case Books.Repo.insert(changeset) do
        {:ok, _format} ->
          conn
          |> put_flash(:info, gettext("Format created successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          Logger.error("cannot create format: #{inspect(changeset.errors)}")

          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("new.html", options(book, format, changeset, return_to))
      end
    else
      conn
      |> put_flash(:error, gettext("Format not found"))
      |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"catalog_id" => book_slug, "id" => format_id} = params) do
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         format when format != nil <- Catalog.get_format(format_id) do
      case Books.Repo.delete(format) do
        {:ok, _format} ->
          conn
          |> put_flash(:info, gettext("Format removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{format_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove format"))
          |> redirect(to: return_to)
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Format not found"))
        |> redirect(to: return_to)
    end
  end
end
