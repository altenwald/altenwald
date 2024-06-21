# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :books,
  ecto_repos: [Books.Repo],
  email_from: {"Altenwald", "info@altenwald.com"}

config :books, Books.Mailer, adapter: Swoosh.Adapters.Local

config :swoosh, :api_client, false

config :books_web,
  ecto_repos: [Books.Repo],
  generators: [context_app: :books, binary_id: true],
  facebook_id: System.get_env("FACEBOOK_ID")

# Configures the endpoint
config :books_web, BooksWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: BooksWeb.ErrorHTML, accepts: ~w(html json), layout: false],
  pubsub_server: Books.PubSub,
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SIGNING_SALT")]

config :books_admin,
  endpoint: BooksWeb.Endpoint,
  url_prefix: "/admin"

config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/books_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:user_id, :pid, :request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mailchimp,
  api_key: System.get_env("MAILCHIMP_API_KEY"),
  mailling_id: System.get_env("MAILCHIMP_MAILLING_ID")

config :geoip, ipinfo_token: System.get_env("GEOIP_IPINFO_TOKEN")

config :phoenix, :template_engines, md: PhoenixMarkdown.Engine

config :phoenix_markdown, :server_tags, :all

config :phoenix_markdown, :earmark, %{
  gfm: true,
  breaks: true
}

config :money,
  default_currency: :EUR,
  separator: ".",
  delimeter: ",",
  symbol: true,
  symbol_on_right: true,
  symbol_space: true

config :books_web, BooksWeb.Gettext, default_locale: "es"

config :gettext, :default_locale, "es"

config :sitemap, host: "https://altenwald.com"

config :remote_ip,
  headers: ["x-forwarded-for"],
  clients: [],
  proxies: []

config :ex_gram, adapter: ExGram.Adapter.Tesla

config :ex_gram, json_engine: Jason

config :books_bot, :granted_users, String.split(System.get_env("GRANTED_USERS", ""), ",")

config :books_bot, :group_chat_ids, String.split(System.get_env("GROUP_CHAT_IDS", ""), ",")

config :books,
  conta_api_key: System.get_env("CONTA_API_KEY", ""),
  conta_base_url: System.get_env("CONTA_BASE_URL", "")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
