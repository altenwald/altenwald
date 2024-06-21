defmodule BooksAdmin.AuthorsController do
  use BooksAdmin, :controller
  require Logger
  alias Books.Catalog

  def new(conn, params) do
    author = Catalog.new_author()
    return_to = params["return_to"]
    render(conn, "new.html", options(author, Catalog.change_author(author), return_to))
  end

  def edit(conn, %{"id" => id} = params) do
    author = Catalog.get_author(id)
    return_to = params["return_to"]
    render(conn, "edit.html", options(author, Catalog.change_author(author), return_to))
  end

  defp options(author, changeset, return_to) do
    [
      title:
        case author do
          %_{id: nil} -> gettext("New author")
          _ -> gettext("Update author")
        end,
      changeset: changeset,
      author: author,
      users: list_users(),
      user_id: if(user = author.user, do: user.id),
      return_to: return_to
    ]
  end

  defp list_users do
    [{gettext("No user selected"), ""}] ++
      for user <- Books.Accounts.list_users() do
        {"#{user.first_name} #{user.last_name} (#{user.email})", user.id}
      end
  end

  def default_return_to(_conn) do
    ""
  end

  def update(conn, %{"id" => author_id, "author" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)

    if author = Catalog.get_author(author_id) do
      changeset = Catalog.change_author(author, params)

      case Catalog.update_author(changeset, params["user_id"]) do
        {:ok, _author} ->
          conn
          |> put_flash(:info, gettext("Profile modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(author, changeset, return_to))
      end
    else
      conn
      |> put_flash(:error, gettext("Profile not found"))
      |> redirect(to: return_to)
    end
  end

  def create(conn, %{"author" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)

    case Catalog.create_author(params) do
      {:ok, _author} ->
        conn
        |> put_flash(:info, gettext("Profile created successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("new.html", options(Catalog.new_author(), changeset, return_to))
    end
  end

  def delete(conn, %{"id" => author_id} = params) do
    return_to = params["return_to"] || default_return_to(conn)

    if author = Catalog.get_author(author_id) do
      case Catalog.delete_author(author.id) do
        {:ok, _author} ->
          conn
          |> put_flash(:info, gettext("Profile removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{author_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove profile"))
          |> redirect(to: return_to)
      end
    else
      conn
      |> put_flash(:error, gettext("Profile not found"))
      |> redirect(to: return_to)
    end
  end
end
