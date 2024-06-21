defmodule BooksAdmin.Application do
  @moduledoc false
  use Application
  @endpoint Application.compile_env!(:books_admin, :endpoint)

  @impl true
  def start(_type, _args) do
    children = [
      # Start Notifiers
      {BooksAdmin.Events.CartEvent, [@endpoint]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BooksAdmin.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
