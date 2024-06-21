defmodule BooksWeb.StripeController do
  use BooksWeb, :controller

  alias Books.Cart
  alias BooksWeb.Payment

  def index(conn, %{"id" => order_id}) do
    order = Cart.ensure_get_order(order_id)
    opts = default_opts(order, id: order_id, api_key: Stripe.cfg(:api_key))
    base = "?provider=stripe&token=#{order.token}"

    conn
    |> put_layout(html: {BooksWeb.Layouts, :stripe})
    |> put_root_layout(false)
    |> assign(:save_url, Routes.stripe_path(conn, :save, order_id))
    |> assign(:return_url, Payment.get_payment_url(conn, base))
    |> assign(:cancel_url, Payment.get_payment_url(conn, "#{base}&cancel"))
    |> assign(:csrf_token, get_csrf_token())
    |> render(opts)
  end

  def save(conn, %{"id" => order_id, "token" => payment_id}) do
    Cart.set_payment_id(order_id, payment_id)
    Cart.set_token(order_id, payment_id)
    text(conn, "ok")
  end
end
