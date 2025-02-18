import Config

# Configure your database
config :books, Books.Repo,
  username: "postgres",
  password: "postgres",
  database: "altenwaldbooks_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :books_web, BooksWeb.Endpoint,
  http: [port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  watchers: [
    node: ["esbuild.js", "--watch", cd: Path.expand("../apps/books_web/assets", __DIR__)]
  ]

# Watch static and templates for browser reloading.
config :books_web, BooksWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/books_web/{live,views}/.*(ex|heex)$",
      ~r"lib/books_web/templates/.*(heex|eex|md)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :paypal,
  client_id: System.get_env("PAYPAL_CLIENT_ID"),
  secret: System.get_env("PAYPAL_SECRET"),
  env: :sandbox

config :stripe,
  api_key: System.get_env("STRIPE_API_KEY"),
  secret: System.get_env("STRIPE_SECRET")

config :books_web, :files_path, "/tmp"

config :books_web, :google_tag_id, System.get_env("GOOGLE_TAG_ID")
config :books_web, :google_tagmanager_id, System.get_env("GOOGLE_TAGMANAGER_ID")

config :books, Books.Mailer, adapter: Swoosh.Adapters.Local

config :swoosh, :api_client, false

config :ex_gram, token: System.get_env("EXGRAM_TOKEN")

config :books_bot, :granted_users, String.split(System.get_env("GRANTED_USERS", ""), ",")
config :books_bot, :group_chat_ids, String.split(System.get_env("GROUP_CHAT_IDS", ""), ",")
