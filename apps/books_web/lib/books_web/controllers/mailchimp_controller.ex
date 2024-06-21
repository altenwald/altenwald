defmodule BooksWeb.MailchimpController do
  use BooksWeb, :controller
  require Logger
  alias Books.Cart

  def handle(conn, %{"type" => type, "data" => %{"email" => email}}) do
    Cart.notify({:mailchimp, type, email})
    text(conn, "OK")
  end

  def handle(conn, params) do
    Logger.warning("unknown mailchimp request: #{inspect(params)}")
    text(conn, "OK")
  end
end
