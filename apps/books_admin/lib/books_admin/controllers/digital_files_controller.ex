defmodule BooksAdmin.DigitalFilesController do
  use BooksAdmin, :controller
  require Logger
  alias Books.{Accounts, Catalog}

  defp default_return_to(conn, book_slug, format_id) do
    Routes.catalog_formats_path(conn, :edit, book_slug, format_id)
  end

  def edit(conn, %{"catalog_id" => book_slug, "formats_id" => format_id, "id" => id} = params) do
    with {:book, book} when book != nil <- {:book, Catalog.get_book_by_slug(book_slug)},
         {:format, format} when format != nil <- {:format, Catalog.get_format(format_id)},
         {:file, file} when file != nil <- {:file, Catalog.get_digital_file(id)} do
      return_to = params["return_to"] || default_return_to(conn, book_slug, format_id)

      render(
        conn,
        "edit.html",
        options(book, format, file, Catalog.change_digital_file(file), return_to)
      )
    else
      {:book, nil} ->
        redirect(conn, to: Routes.home_path(conn, :index))

      {:format, nil} ->
        redirect(conn, to: Routes.catalog_path(conn, :show, book_slug))

      {:file, nil} ->
        redirect(conn, to: Routes.catalog_formats_path(conn, :edit, book_slug, format_id))
    end
  end

  def new(conn, %{"catalog_id" => book_slug, "formats_id" => format_id} = params) do
    with {:book, book} when book != nil <- {:book, Catalog.get_book_by_slug(book_slug)},
         {:format, format} when format != nil <- {:format, Catalog.get_format(format_id)} do
      file = Catalog.new_digital_file(format_id)
      return_to = params["return_to"] || default_return_to(conn, book_slug, format_id)

      render(
        conn,
        "new.html",
        options(book, format, file, Catalog.change_digital_file(file), return_to)
      )
    else
      {:book, nil} -> redirect(conn, to: Routes.home_path(conn, :index))
      {:format, nil} -> redirect(conn, to: Routes.catalog_path(conn, :show, book_slug))
    end
  end

  defp list_file_types do
    [
      {"PDF", "pdf"},
      {"ePUB", "epub"}
    ]
  end

  defp options(book, format, file, changeset, return_to) do
    [
      title:
        case format do
          %_{id: nil} ->
            gettext("New digital file for %{slug}", slug: book.slug)

          _ ->
            gettext("Digital file for %{slug}", slug: book.slug)
        end,
      book: book,
      changeset: changeset,
      format: format,
      file: file,
      file_types: list_file_types(),
      return_to: return_to
    ]
  end

  def update(
        conn,
        %{
          "catalog_id" => book_slug,
          "formats_id" => format_id,
          "id" => file_id,
          "digital_file" => params
        } = global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug, format_id)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         format when format != nil <- Catalog.get_format(format_id),
         file when file != nil <- Catalog.get_digital_file(file_id) do
      params = Map.put(params, "format_id", format.id)
      changeset = Catalog.change_digital_file(file, params)

      case Books.Repo.update(changeset) do
        {:ok, new_file} ->
          if file.filename != new_file.filename do
            Accounts.send_digital_file_upgrade(book)
          end

          conn
          |> put_flash(:info, gettext("Digital file modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(book, format, file, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Digital file not found"))
        |> redirect(to: return_to)
    end
  end

  def create(
        conn,
        %{"catalog_id" => book_slug, "formats_id" => format_id, "digital_file" => params} =
          global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug, format_id)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         format when format != nil <- Catalog.get_format(format_id) do
      file = Catalog.new_digital_file(format_id)
      params = Map.put(params, "format_id", format_id)
      changeset = Catalog.change_digital_file(file, params)

      case Books.Repo.insert(changeset) do
        {:ok, _file} ->
          conn
          |> put_flash(:info, gettext("Digital file created successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          Logger.error("cannot create digital file: #{inspect(changeset.errors)}")

          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("new.html", options(book, format, file, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Digital not found"))
        |> redirect(to: return_to)
    end
  end

  def delete(
        conn,
        %{"catalog_id" => book_slug, "formats_id" => format_id, "id" => file_id} = params
      ) do
    return_to = params["return_to"] || default_return_to(conn, book_slug, format_id)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         format when format != nil <- Catalog.get_format(format_id),
         file when file != nil <- Catalog.get_digital_file(file_id) do
      case Books.Repo.delete(file) do
        {:ok, _file} ->
          conn
          |> put_flash(:info, gettext("Digital file removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{file_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove digital file"))
          |> redirect(to: return_to)
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Digital file not found"))
        |> redirect(to: return_to)
    end
  end
end
