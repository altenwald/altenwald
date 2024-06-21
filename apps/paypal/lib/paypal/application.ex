defmodule Paypal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = maybe_add_paypal_auth()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Paypal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  if Mix.env() == :test do
    defp maybe_add_paypal_auth, do: []
  else
    defp maybe_add_paypal_auth, do: [Paypal.Auth]
  end
end
