defmodule BooksWeb.BundleCoverComponent do
  use BooksWeb, :component

  def img(assigns) do
    ~H"""
    <img
      class={assigns[:class] || "bundle_cover"}
      alt={assigns[:alt] || gettext("bundle cover")}
      src={img_path(@conn, @bundle)}
    />
    """
  end

  def img_path(conn, bundle) do
    Routes.static_path(conn, "/images/covers/bundle-#{bundle.slug}.png")
  end

  def img_url(conn, bundle) do
    Routes.static_url(conn, "/images/covers/bundle-#{bundle.slug}.png")
  end
end
