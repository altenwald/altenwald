defmodule BooksAdmin.LandingsController do
  use BooksAdmin, :controller
  require Logger
  alias Books.{Ads, Catalog, Landings}

  defp default_return_to(conn) do
    Routes.landings_path(conn, :index)
  end

  def index(conn, _params) do
    render(conn, "index.html",
      title: gettext("Landing"),
      landings: Landings.list_landings()
    )
  end

  def delete(conn, %{"id" => landing_id} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    landing = Landings.get_landing!(landing_id)

    case Landings.delete_landing(landing) do
      {:ok, _landing} ->
        conn
        |> put_flash(:info, gettext("Landing page removed successfully!"))
        |> redirect(to: return_to)

      {:error, reason} ->
        Logger.error("cannot remove landing #{landing_id}, reason: #{inspect(reason)}")

        conn
        |> put_flash(:error, gettext("Cannot remove landing page"))
        |> redirect(to: return_to)
    end
  end

  def new(conn, params) do
    landing = Landings.new_landing()
    return_to = params["return_to"] || default_return_to(conn)
    render(conn, "new.html", options(landing, Landings.change_landing(landing), return_to))
  end

  def edit(conn, %{"id" => landing_id} = params) do
    landing = Landings.get_landing!(landing_id)
    return_to = params["return_to"] || default_return_to(conn)
    render(conn, "edit.html", options(landing, Landings.change_landing(landing), return_to))
  end

  defp options(landing, changeset, return_to) do
    [
      title:
        case landing do
          %_{id: nil} -> gettext("New landing page")
          _ -> gettext("Update landing page")
        end,
      changeset: changeset,
      landing: landing,
      books: list_all_books(),
      bundles: list_all_bundles(),
      languages: list_languages(),
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

  defp list_all_books do
    for book <- Catalog.list_all_books_simple() do
      {Catalog.get_full_book_title(book), book.id}
    end
  end

  defp list_all_bundles do
    for bundle <- Ads.list_bundles(), do: {bundle.name, bundle.id}
  end

  def update(conn, %{"id" => landing_id, "landing" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)
    landing = Landings.get_landing!(landing_id)

    params =
      params
      |> Map.put("slugs", String.split(params["slugs"] || "", ",", trim: true))
      |> Map.put(
        "engagement_phrases",
        String.split(params["engagement_phrases"] || "", "\n", trim: true)
      )

    case Landings.update_landing(landing, params) do
      {:ok, _landing} ->
        conn
        |> put_flash(:info, gettext("Landing page modified successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot update landing page: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("edit.html", options(landing, changeset, return_to))
    end
  end

  def create(conn, %{"landing" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)

    params =
      params
      |> Map.put("slugs", String.split(params["slugs"] || "", ",", trim: true))
      |> Map.put(
        "engagement_phrases",
        String.split(params["engagement_phrases"] || "", "\n", trim: true)
      )

    case Landings.create_landing(params) do
      {:ok, _landing} ->
        conn
        |> put_flash(:info, gettext("Landing page created successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot create landing page: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("new.html", options(Landings.new_landing(), changeset, return_to))
    end
  end
end
