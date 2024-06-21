defmodule BooksAdmin.BundlesController do
  use BooksAdmin, :controller
  require Logger
  alias Books.{Ads, Catalog}

  defp default_return_to(conn) do
    Routes.bundles_path(conn, :index)
  end

  def index(conn, _params) do
    render(conn, "index.html",
      title: gettext("Bundle"),
      bundles: Ads.list_bundles()
    )
  end

  def delete(conn, %{"id" => bundle_id} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    bundle = Ads.get_bundle!(bundle_id)

    case Ads.delete_bundle(bundle) do
      {:ok, _bundle} ->
        conn
        |> put_flash(:info, gettext("Bundle removed successfully!"))
        |> redirect(to: return_to)

      {:error, reason} ->
        Logger.error("cannot remove #{bundle_id}, reason: #{inspect(reason)}")

        conn
        |> put_flash(:error, gettext("Cannot remove bundle"))
        |> redirect(to: return_to)
    end
  end

  def new(conn, params) do
    bundle = Ads.new_bundle()
    return_to = params["return_to"] || default_return_to(conn)
    render(conn, "new.html", options(bundle, Ads.change_bundle(bundle), return_to))
  end

  def edit(conn, %{"id" => id} = params) do
    bundle = Ads.get_bundle!(id)
    return_to = params["return_to"] || default_return_to(conn)
    render(conn, "edit.html", options(bundle, Ads.change_bundle(bundle), return_to))
  end

  defp options(bundle, changeset, return_to) do
    [
      title:
        case bundle do
          %_{id: nil} -> gettext("New bundle")
          _ -> gettext("Update bundle")
        end,
      changeset: changeset,
      bundle: bundle,
      formats: list_all_formats(),
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

  defp list_all_formats do
    for format <- Catalog.list_all_formats() do
      {"[#{format.name}] #{Catalog.get_full_book_title(format.book)}", format.id}
    end
  end

  def update(conn, %{"id" => bundle_id, "bundle" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)
    bundle = Ads.get_bundle!(bundle_id)

    case Ads.update_bundle(bundle, params) do
      {:ok, _bundle} ->
        conn
        |> put_flash(:info, gettext("Bundle modified successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot update bundle: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("edit.html", options(bundle, changeset, return_to))
    end
  end

  def create(conn, %{"bundle" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)

    case Ads.create_bundle(params) do
      {:ok, _bundle} ->
        conn
        |> put_flash(:info, gettext("Bundle created successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot create bundle: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("new.html", options(Ads.new_bundle(), changeset, return_to))
    end
  end
end
