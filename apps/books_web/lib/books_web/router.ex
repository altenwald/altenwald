defmodule BooksWeb.Router do
  use BooksWeb, :router

  import BooksWeb.UserAuth

  #   FIXME: implement secure browser headers
  # if Mix.env() == :dev do
  #   @content_security_policy "default-src 'self' 'unsafe-eval' 'unsafe-inline'; " <>
  #     "connect-src ws://#{@host}:*; " <>
  #     "img-src 'self' blob: data:"
  # else
  #   @content_security_policy "default-src 'self'; connect-src wss://#{@host}; img-src 'self' blob:;"
  # end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BooksWeb.Layouts, :root}
    plug :put_layout, html: {BooksWeb.Layouts, :app}
    plug :protect_from_forgery
    #   FIXME: implement secure browser headers
    # plug :put_secure_browser_headers, %{"content-security-policy" => @content_security_policy}
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :put_user_token
    plug RemoteIp, Application.get_all_env(:remote_ip)
    plug BooksWeb.Locale
  end

  pipeline :api do
    plug RemoteIp, Application.get_all_env(:remote_ip)
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :menu
  end

  defp menu(conn, _params) do
    assigns = Map.put(conn.assigns, :conn, conn)
    assign(conn, :menu, BooksWeb.Layouts.menu(assigns))
  end

  scope "/admin", BooksAdmin do
    pipe_through [:browser, :require_admin, :admin]
    forward "/", Router
  end

  scope "/api/v1", BooksWeb do
    pipe_through :api

    # For Payment webhooks (from external APIs)
    post "/mailchimp", MailchimpController, :handle
    get "/mailchimp", MailchimpController, :handle
  end

  scope "/", BooksWeb do
    pipe_through :browser

    get "/", CatalogController, :index
    get "/catalog/:book_lang", CatalogController, :index
    get "/book/:book_slug", CatalogController, :book
    post "/book/:book_slug", CatalogController, :subscribe

    get "/cart", CartController, :index
    get "/cart/add/:format", CartController, :add
    get "/cart/rem/:format", CartController, :rem
    get "/cart/bundle/:slug", CartController, :bundle
    post "/cart", CartController, :payment
    put "/cart", CartController, :payment
    get "/cart/payment", CartController, :check_payment
    post "/cart/code", CartController, :discount

    get "/cart/payment/stripe/:id", StripeController, :index
    post "/cart/payment/stripe/:id", StripeController, :save

    get "/book/:token/:order/:format", DownloadController, :download

    get "/privacidad", LegalController, :privacy_es
    get "/politica-cookies", LegalController, :cookies_es
    get "/acuerdo-de-uso", LegalController, :tos_es
    get "/acerca-de", LegalController, :about_es

    get "/privacy", LegalController, :privacy_en
    get "/cookies", LegalController, :cookies_en
    get "/tos", LegalController, :tos_en
    get "/about", LegalController, :about_en

    get "/lang/:lang", LocaleController, :set_lang

    delete "/logout", UserSessionController, :delete
    get "/logout", UserSessionController, :logout
    get "/user-confirm", UserConfirmationController, :new
    post "/user-confirm", UserConfirmationController, :create
    get "/user-confirm/:token", UserConfirmationController, :edit
    post "/user-confirm/:token", UserConfirmationController, :update

    get "/posts", PostsController, :index
    get "/:year/:month/:day/:slug", PostsController, :show

    get "/landing/:slug", LandingController, :show
    post "/landing/:slug", LandingController, :subscribe
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BooksWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BooksWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/register", UserRegistrationController, :new
    # TODO: register using a subscritpion
    # post "/register", UserRegistrationController, :create
    get "/login", UserSessionController, :new
    post "/login", UserSessionController, :create
    get "/forgot-password", UserResetPasswordController, :new
    post "/forgot-password", UserResetPasswordController, :create
    get "/reset-password/:token", UserResetPasswordController, :edit
    put "/reset-password/:token", UserResetPasswordController, :update
  end

  scope "/", BooksWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/user-settings", UserSettingsLive.Edit, :edit
    live "/:lang/user-settings", UserSettingsLive.Edit, :edit

    get "/user-settings/subscribe/:book_slug", UserSettingsController, :subscribe
    get "/user-settings/unsubscribe/:book_slug", UserSettingsController, :unsubscribe
    get "/user-settings/confirm_email/:token", UserSettingsController, :confirm_email
    get "/bookshelf", UserBookshelfController, :index
    get "/bookshelf/download/:file_id", UserBookshelfController, :download
    get "/my-orders", CartController, :my_orders
    get "/my-order/:order_id", CartController, :my_order
    resources "/posts", PostsController, except: [:index, :show]
    post "/posts/:slug/comment", CommentsController, :create
  end

  ##  token for websocket from session (order)
  defp put_user_token(conn, _) do
    if cookie = conn.cookies["_books_key"] do
      token = Phoenix.Token.sign(conn, "cart socket", cookie)
      assign(conn, :user_token, token)
    else
      conn
    end
  end

  scope "/", BooksWeb do
    pipe_through :browser

    get "/en/*redirect", LocaleController, :set_lang_en
    get "/es/*redirect", LocaleController, :set_lang_es

    post "/en/*redirect", LocaleController, :set_lang_en
    post "/es/*redirect", LocaleController, :set_lang_es

    put "/en/*redirect", LocaleController, :set_lang_en
    put "/es/*redirect", LocaleController, :set_lang_es

    delete "/en/*redirect", LocaleController, :set_lang_en
    delete "/es/*redirect", LocaleController, :set_lang_es

    # keep always the last one
    get "/:slug", LandingController, :show
  end
end
