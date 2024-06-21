defmodule BooksBot.Application do
  use Application

  @impl Application
  def start(_start_type, _start_args) do
    children = [
      # Start the Finch HTTP client for sending emails
      ExGram,
      {BooksBot.Action, method: :polling, token: get_token()},
      BooksBot.Notification
    ]

    opts = [strategy: :one_for_one, name: BooksBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_token do
    Application.get_env(:ex_gram, :token) ||
      raise """
      TOKEN WAS NOT CONFIGURED!!!
      """
  end
end
