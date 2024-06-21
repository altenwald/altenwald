defmodule Books.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    {:ok, _} = EctoBootMigration.migrate(:books)

    # Define workers and child supervisors to be supervised
    children = [
      # Start DynamicSupervisor y Registry for Orders (Cart)
      {Registry, keys: :unique, name: Books.Cart.registry_name()},
      {DynamicSupervisor, strategy: :one_for_one, name: Books.Cart.supervisor_name()},
      # Phoenix. PubSub and Presence
      {Phoenix.PubSub, [name: Books.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start the Ecto repository
      Books.Repo,
      # Schedulers
      Books.Schedulers.Stats,
      Books.Schedulers.Order,
      # Notifiers
      Books.Cart.Notifier.Balances,
      Books.Cart.Notifier.Logger,
      Books.Cart.Notifier.Mailchimp,
      Books.Cart.Notifier.Bookshelf,
      Books.Cart.Notifier.Conta
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Books.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
