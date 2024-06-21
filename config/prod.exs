import Config

config :books_web, BooksWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: {:system, "PORT"}],
  url: [host: "${DOMAIN}", port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: "${SECRET_KEY_BASE}",
  server: true,
  root: ".",
  version: Application.spec(:phoenix_distillery, :vsn)

config :logger, level: :info

config :paypal,
  client_id: "${PAYPAL_CLIENT_ID}",
  secret: "${PAYPAL_SECRET}",
  env: :prod

config :stripe,
  api_key: "${STRIPE_API_KEY}",
  secret: "${STRIPE_SECRET}"

config :books_web, :files_path, "${DOWNLOAD_FILES_PATH}"
config :books_web, :pub_path, "${PUB_FILES_PATH}"
config :books_admin, :pub_path, "${PUB_FILES_PATH}"

config :books_web, :google_tag_id, "${GOOGLE_TAG_ID}"
config :books_web, :google_tagmanager_id, "${GOOGLE_TAGMANAGER_ID}"

# Configure your database
config :books, Books.Repo,
  username: "${POSTGRES_USER}",
  password: "${POSTGRES_PASS}",
  database: "${POSTGRES_DATABASE}",
  hostname: "${POSTGRES_HOSTNAME}",
  port: 5433,
  pool_size: 10

config :books, Books.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: "${MAILGUN_API_KEY}",
  domain: "${MAILGUN_DOMAIN}",
  base_url: "https://api.eu.mailgun.net/v3"

config :swoosh, :api_client, Swoosh.ApiClient.Hackney

config :ex_gram, token: "${EXGRAM_TOKEN}"
