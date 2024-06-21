defmodule BooksAdmin.ContentsController do
  use BooksAdmin, :controller
  require Logger
  alias Books.Catalog
  alias BooksAdmin.ContentsHTML, as: View

  def index(conn, %{"catalog_id" => book_slug}) do
    book = Catalog.get_book_by_slug(book_slug)

    render(conn, "index.html",
      title: gettext("Contents of %{book_slug}", book_slug: book_slug),
      book: book,
      contents: Catalog.list_contents_by_book_id(book.id),
      bulk_actions: list_bulk_actions()
    )
  end

  defp list_bulk_actions do
    [
      {"", ""},
      {gettext("Mark as 'todo'"), "todo"},
      {gettext("Mark as 'prepared'"), "prepared"},
      {gettext("Mark as 'reviewed'"), "reviewed"},
      {gettext("Mark as 'done'"), "done"},
      {gettext("Remove"), "remove"}
    ]
  end

  defp default_return_to(conn, book_slug) do
    Routes.catalog_contents_path(conn, :index, book_slug)
  end

  def edit(conn, %{"catalog_id" => book_slug, "id" => id} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    content = Catalog.get_content(id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)
    render(conn, "edit.html", options(book, content, Catalog.change_content(content), return_to))
  end

  def new(conn, %{"catalog_id" => book_slug} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    content = Catalog.new_content(book.id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)
    render(conn, "new.html", options(book, content, Catalog.change_content(content), return_to))
  end

  def update(
        conn,
        %{"catalog_id" => book_slug, "id" => content_id, "content" => params} = global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         params = Map.put(params, "book_id", book.id),
         content when content != nil <- Catalog.get_content(content_id) do
      changeset = Catalog.change_content(content, params)

      case Books.Repo.update(changeset) do
        {:ok, _content} ->
          conn
          |> put_flash(:info, gettext("Content modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(book, content, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Content not found"))
        |> redirect(to: return_to)
    end
  end

  def create(conn, %{"catalog_id" => book_slug, "content" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    if book = Catalog.get_book_by_slug(book_slug) do
      content = Catalog.new_content(book.id)
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_content(content, params)

      case Books.Repo.insert(changeset) do
        {:ok, _content} ->
          conn
          |> put_flash(:info, gettext("Content created successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("new.html", options(book, content, changeset, return_to))
      end
    else
      conn
      |> put_flash(:error, gettext("Content not found"))
      |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"catalog_id" => book_slug, "id" => content_id} = params) do
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         content when content != nil <- Catalog.get_content(content_id) do
      case Books.Repo.delete(content) do
        {:ok, _content} ->
          conn
          |> put_flash(:info, gettext("Content removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{content_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove content"))
          |> redirect(to: return_to)
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Content not found"))
        |> redirect(to: return_to)
    end
  end

  def bulk_action(conn, %{"catalog_id" => book_id, "content_ids" => []}) do
    conn
    |> put_flash(:error, gettext("No affected rows, you have to select at least one row."))
    |> redirect(to: Routes.catalog_contents_path(conn, :index, book_id))
  end

  def bulk_action(conn, %{
        "bulk_action" => bulk_action,
        "catalog_id" => book_id,
        "content_ids" => content_ids
      })
      when is_list(content_ids) do
    case bulk_action do
      "todo" ->
        Catalog.update_all_contents(content_ids, status: :todo)

      "prepared" ->
        Catalog.update_all_contents(content_ids, status: :prepared)

      "reviewed" ->
        Catalog.update_all_contents(content_ids, status: :reviewed)

      "done" ->
        Catalog.update_all_contents(content_ids, status: :done)

      "remove" ->
        Catalog.delete_all_contents(content_ids)
    end
    |> case do
      {0, _affected_rows} ->
        conn
        |> put_flash(:error, gettext("No modified rows, something wrong happened."))
        |> redirect(to: Routes.catalog_contents_path(conn, :index, book_id))

      {rows, _affected_rows} ->
        conn
        |> put_flash(:info, gettext("%{rows} affected and modified/removed.", rows: rows))
        |> redirect(to: Routes.catalog_contents_path(conn, :index, book_id))
    end
  end

  defp options(book, content, changeset, return_to) do
    [
      title:
        case content do
          %_{id: nil} ->
            gettext("New content from %{slug}", slug: book.slug)

          _ ->
            gettext("Content %{content_type} %{order} from %{slug}",
              content_type: View.translate_type(content.chapter_type),
              order: content.order,
              slug: book.slug
            )
        end,
      book: book,
      changeset: changeset,
      content: content,
      statuses: list_statuses(),
      types: list_chapter_types(),
      return_to: return_to
    ]
  end

  defp list_statuses do
    [
      {"", ""},
      {gettext("Todo"), "todo"},
      {gettext("Prepared"), "prepared"},
      {gettext("Reviewed"), "reviewed"},
      {gettext("Done"), "done"}
    ]
  end

  defp list_chapter_types do
    [
      {"", ""},
      {gettext("Preface"), "1 preface"},
      {gettext("Introduction"), "2 intro"},
      {gettext("Chapter"), "3 chapter"},
      {gettext("Appendix"), "4 appendix"}
    ]
  end
end
