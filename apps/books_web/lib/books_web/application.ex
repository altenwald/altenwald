defmodule BooksWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias BooksWeb.Schedulers.Session

  @impl true
  def start(_type, _args) do
    Session.init()

    children = [
      # Start the Telemetry supervisor
      BooksWeb.Telemetry,
      # Start the Endpoint (http/https)
      BooksWeb.Endpoint,
      # Schedulers
      BooksWeb.Schedulers.Sitemaps,
      BooksWeb.Schedulers.Session,
      # Start Notifiers
      BooksWeb.Events.Order.Account
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BooksWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BooksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
