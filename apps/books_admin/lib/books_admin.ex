defmodule BooksAdmin do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, html, channels and so on.

  This can be used in your application as:

      use BooksAdmin, :controller
      use BooksAdmin, :html

  The definitions below will be executed for every html,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import BooksAdmin.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html],
        layouts: [html: BooksAdmin.Layouts]

      import Plug.Conn
      import BooksAdmin.Gettext
      alias BooksAdmin.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {BooksAdmin.Layouts, :app}

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
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include shared imports and aliases for html
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      use Phoenix.HTML
      # Core UI components and translation
      import BooksAdmin.CoreComponents
      import BooksAdmin.Gettext

      import BooksAdmin.Router.Helpers, except: [static_path: 2]

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

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
        endpoint: BooksAdmin.Endpoint,
        router: BooksAdmin.Router
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/html/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  @project_vsn Mix.Project.config()[:version]
  def vsn, do: @project_vsn
end
