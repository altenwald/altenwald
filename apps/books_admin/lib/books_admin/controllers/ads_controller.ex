defmodule BooksAdmin.AdsController do
  use BooksAdmin, :controller
  require Logger
  alias Books.{Ads, Catalog}

  @default_pub_path "pub"

  def index(conn, _params) do
    render(conn, "index.html", ads_carousel: Ads.list_ads_carousel())
  end

  defp list_books do
    for book <- Catalog.list_all_books_simple() do
      {Catalog.get_full_book_title(book), book.id}
    end
  end

  defp list_bundles do
    for bundle <- Ads.list_bundles() do
      {bundle.name, bundle.id}
    end
  end

  defp pub_path do
    Application.get_env(:books_admin, :pub_path, @default_pub_path)
  end

  defp get_carousel_image(name) do
    Path.join([pub_path(), "carousel", "desktop", name])
  end

  defp get_carousel_images do
    Path.wildcard(get_carousel_image("*.png"))
    |> Enum.map(&Path.basename/1)
  end

  defp options(carousel, changeset, return_to) do
    [
      title:
        case carousel do
          %_{id: nil} -> gettext("New carousel ad")
          _ -> gettext("Update carousel ad")
        end,
      changeset: changeset,
      carousel: carousel,
      images: get_carousel_images(),
      books: list_books(),
      bundles: list_bundles(),
      return_to: return_to
    ]
  end

  defp default_return_to(conn) do
    Routes.ads_path(conn, :index)
  end

  def edit(conn, %{"id" => carousel_id} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    carousel = Ads.get_carousel!(carousel_id)
    changeset = Ads.change_carousel(carousel)

    render(conn, "edit.html", options(carousel, changeset, return_to))
  end

  def new(conn, params) do
    return_to = params["return_to"] || default_return_to(conn)
    carousel = Ads.new_carousel()
    changeset = Ads.change_carousel(carousel)

    render(conn, "new.html", options(carousel, changeset, return_to))
  end

  def delete(conn, %{"id" => carousel_id} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    carousel = Ads.get_carousel!(carousel_id)

    case Ads.delete_carousel(carousel) do
      {:ok, _carousel} ->
        conn
        |> put_flash(:info, gettext("Carousel Ad removed successfully!"))
        |> redirect(to: return_to)

      {:error, reason} ->
        Logger.error("cannot remove #{carousel_id}, reason: #{inspect(reason)}")

        conn
        |> put_flash(:error, gettext("Cannot remove carousel ad"))
        |> redirect(to: return_to)
    end
  end

  def update(conn, %{"id" => carousel_id, "carousel" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)
    carousel = Ads.get_carousel!(carousel_id)

    case Ads.update_carousel(carousel, params) do
      {:ok, _carousel} ->
        conn
        |> put_flash(:info, gettext("Carousel Ad modified successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot update carousel ad: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("edit.html", options(carousel, changeset, return_to))
    end
  end

  def create(conn, %{"carousel" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)

    case Ads.create_carousel(params) do
      {:ok, _carousel} ->
        conn
        |> put_flash(:info, gettext("Carousel Ad created successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot create carousel ad: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("new.html", options(Ads.new_carousel(), changeset, return_to))
    end
  end
end
