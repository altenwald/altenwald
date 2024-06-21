import Config

# Configure your database
config :books, Books.Repo,
  username: "postgres",
  password: "postgres",
  database: "altenwaldbooks_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :books_web, BooksWeb.Endpoint,
  http: [port: 4002],
  server: true,
  secret_key_base: "94yKTKrrQ9yGJUWT2haIPCjqxhc21DqBU3Toe9p8G+/MiYhl0Zqp58sxJlIguY9B"

# Print only warnings and errors during test
config :logger, level: :warning

config :books, :sql_sandbox, true

config :paypal,
  client_id: "client_id",
  secret: "secret",
  env: :sandbox

config :stripe,
  api_key: "STRIPE_API_KEY",
  secret: "STRIPE_SECRET"

config :books_web, :files_path, "/tmp"

config :tesla, Mailchimp, adapter: Tesla.Mock
config :tesla, Geoip, adapter: Tesla.Mock
config :tesla, Paypal, adapter: Tesla.Mock
config :tesla, Paypal.Auth, adapter: Tesla.Mock

config :books, Books.Mailer, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, false

config :ex_gram, test_environment: true
config :ex_gram, token: System.get_env("EXGRAM_TOKEN_TEST")
