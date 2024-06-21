defmodule Paypal do
  use Tesla
  require Logger

  @api_prod_url "https://api.paypal.com"
  @api_sandbox_url "https://api.sandbox.paypal.com"

  plug(Tesla.Middleware.BaseUrl, cfg(:url))

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/json"},
    {"accept-language", "en_US"},
    {"authorization", "bearer " <> Paypal.Auth.get_token()}
  ])

  plug(Tesla.Middleware.JSON)

  def cfg(:url) do
    case cfg(:env) do
      :sandbox -> @api_sandbox_url
      :prod -> @api_prod_url
    end
  end

  def cfg(key), do: Application.get_env(:paypal, key)

  def list_payments(query \\ []) do
    get("/v1/payments/payment", query: query)
  end

  def show_payment_details(id) do
    get("/v1/payments/payment/#{id}")
  end

  def create_payment(data) do
    Logger.debug("send payment: #{inspect(data)}")
    post("/v1/payments/payment", data)
  end

  def execute_payment(payment_id, payerId) do
    data = %{"payer_id" => payerId}
    Logger.info("executed payment #{payment_id} with payer_id=#{payerId}")
    post("/v1/payments/payment/#{payment_id}/execute", data)
  end

  def list_transactions(query \\ []) do
    get("/v1/reporting/transactions", query: query)
  end

  def list_invoices(query \\ []) do
    get("/v1/invoicing/invoices", query: query)
  end

  def get_invoice(id) do
    get("/v1/invoicing/invoices/#{id}")
  end

  def list_activities(query \\ []) do
    get("/v1/activities/activities", query: query)
  end
end
