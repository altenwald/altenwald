defmodule BooksWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :books_web

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :ets,
    table: :session,
    key: "_books_key",
    max_age: 3_600 * 6
  ]

  def remote_ip(ip) when is_tuple(ip) do
    to_string(:inet_parse.ntoa(ip))
  end

  def remote_ip(%Plug.Conn{remote_ip: remote_ip}) do
    remote_ip(remote_ip)
  end

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  socket "/socket", BooksWeb.BooksSocket,
    websocket: [connect_info: [:peer_data, :x_headers]],
    longpoll: [connect_info: [:peer_data, :x_headers]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :books_web,
    gzip: false,
    cache_control_for_etags: "public, max-age=86400",
    only: BooksWeb.static_paths()

  if Mix.env() == :dev do
    plug Plug.Static,
      at: "/images/covers",
      from: "pub/covers",
      only_matching: ~w(small big bundle)

    plug Plug.Static,
      at: "/images/authors",
      from: "pub/authors"

    plug Plug.Static,
      at: "/images/projects",
      from: "pub/projects"

    plug Plug.Static,
      at: "/images/carousel",
      from: "pub/carousel"

    plug Plug.Static,
      at: "/images/posts",
      from: "pub/posts"

    plug Plug.Static,
      at: "/images/backgrounds",
      from: "pub/backgrounds"

    plug Plug.Static,
      at: "/images/landings",
      from: "pub/landings"

    plug Plug.Static,
      at: "/images/reviewers",
      from: "pub/reviewers"

    plug Plug.Static,
      at: "/images/shoplinks",
      from: "pub/shoplinks"
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :books_web
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug BooksWeb.Router
end
