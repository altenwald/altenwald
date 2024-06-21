defmodule Stripe do
  use Tesla
  require Logger

  plug(Tesla.Middleware.BaseUrl, "https://api.stripe.com")
  plug(Tesla.Middleware.Headers, [{"authorization", "bearer " <> cfg(:secret)}])
  plug(Tesla.Middleware.FormUrlencoded)
  plug(Tesla.Middleware.JSON)

  def cfg(key), do: Application.get_env(:stripe, key)

  def charges(amount, currency, description, token) do
    args = [
      amount: amount,
      currency: String.downcase(to_string(currency)),
      description: description,
      source: token
    ]

    case post("/v1/charges", args) do
      {:ok, resp} -> resp.body
      {:error, _} = error -> error
    end
  end

  def get_charge(payment_id) do
    get("/v1/charges/#{payment_id}")
  end

  def get_transaction(txn) do
    get("/v1/balance_transactions/#{txn}")
  end
end
