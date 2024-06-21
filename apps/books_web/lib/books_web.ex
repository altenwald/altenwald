defmodule BooksWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use BooksWeb, :controller
      use BooksWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """
  alias Books.Ads.Offer

  def static_paths, do: ~w(assets css fonts images js favicon robots.txt sitemaps vendor)

  def router do
    quote do
      use Phoenix.Router, helpers: true

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import BooksWeb.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html],
        layouts: [html: BooksWeb.Layouts]

      import Plug.Conn
      import BooksWeb.Gettext
      alias BooksWeb.Router.Helpers, as: Routes

      import BooksWeb, only: [default_opts: 1, default_opts: 2, default_opts: 3]

      unquote(verified_routes())
    end
  end

  def default_opts(order_or_conn, opts \\ [])

  def default_opts(%Plug.Conn{} = conn, opts) do
    order =
      conn
      |> Plug.Conn.get_session(:order_id)
      |> Books.Cart.get_order()

    [
      link: "catalog",
      book: false,
      books: false,
      recursos: false,
      comentarios: false,
      code_offer: Offer.changeset(),
      cart: order,
      alerts: Books.Engagement.alerts_by_lang(conn.assigns.locale)
    ] ++ opts
  end

  def default_opts(order, opts) do
    [
      link: "",
      book: false,
      books: false,
      comentarios: false,
      code_offer: Offer.changeset(),
      cart: order,
      alerts: []
    ] ++ opts
  end

  def default_opts(conn, order, opts) do
    [
      link: "",
      book: false,
      books: false,
      comentarios: false,
      code_offer: Offer.changeset(),
      cart: order,
      alerts: Books.Engagement.alerts_by_lang(conn.assigns.locale)
    ] ++ opts
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {BooksWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(html_helpers())

      def money(nil), do: Money.to_string(Money.new(0))
      def money(price), do: Money.to_string(price)

      def request_url(conn) do
        #  cannot use Plug.Conn.request_url/1 directly because it's
        #  always returning the `http` schema instead of `https`.
        path =
          conn
          |> Plug.Conn.request_url()
          |> URI.parse()
          |> Map.get(:path)

        BooksWeb.Endpoint.url()
        |> URI.parse()
        |> URI.merge(path)
        |> to_string()
      end
    end
  end

  defp html_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      # Core UI components and translation
      import BooksWeb.CoreComponents
      import BooksWeb.Gettext

      import BooksWeb.FormHelpers
      alias BooksWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: BooksWeb.Endpoint,
        router: BooksWeb.Router,
        statics: BooksWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  @project_vsn Mix.Project.config()[:version]
  def vsn, do: @project_vsn
end
