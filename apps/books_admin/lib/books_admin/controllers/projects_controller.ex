defmodule BooksAdmin.ProjectsController do
  use BooksAdmin, :controller
  require Logger
  alias Books.Catalog

  defp default_return_to(conn, book_slug) do
    Routes.catalog_path(conn, :show, book_slug, tab: "projects")
  end

  def edit(conn, %{"catalog_id" => book_slug, "id" => id} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    project = Catalog.get_project(id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)
    render(conn, "edit.html", options(book, project, Catalog.change_project(project), return_to))
  end

  def new(conn, %{"catalog_id" => book_slug} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    project = Catalog.new_project(book.id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)
    render(conn, "new.html", options(book, project, Catalog.change_project(project), return_to))
  end

  defp options(book, project, changeset, return_to) do
    [
      title:
        case project do
          %_{id: nil} ->
            gettext("New project from %{slug}", slug: book.slug)

          _ ->
            gettext("Project from %{slug}", slug: book.slug)
        end,
      book: book,
      changeset: changeset,
      project: project,
      return_to: return_to
    ]
  end

  def update(
        conn,
        %{"catalog_id" => book_slug, "id" => project_id, "project" => params} = global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         project when project != nil <- Catalog.get_project(project_id) do
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_project(project, params)

      case Books.Repo.update(changeset) do
        {:ok, _project} ->
          conn
          |> put_flash(:info, gettext("Project modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(book, project, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Project not found"))
        |> redirect(to: return_to)
    end
  end

  def create(conn, %{"catalog_id" => book_slug, "project" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    if book = Catalog.get_book_by_slug(book_slug) do
      project = Catalog.new_project(book.id)
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_project(project, params)

      case Books.Repo.insert(changeset) do
        {:ok, _project} ->
          conn
          |> put_flash(:info, gettext("Project created successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("new.html", options(book, project, changeset, return_to))
      end
    else
      conn
      |> put_flash(:error, gettext("Project not found"))
      |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"catalog_id" => book_slug, "id" => project_id} = params) do
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         project when project != nil <- Catalog.get_project(project_id) do
      case Books.Repo.delete(project) do
        {:ok, _project} ->
          conn
          |> put_flash(:info, gettext("Project removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{project_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove project"))
          |> redirect(to: return_to)
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Project not found"))
        |> redirect(to: return_to)
    end
  end
end
