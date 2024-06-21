defmodule BooksWeb.Payment do
  alias BooksWeb.Router.Helpers, as: Routes

  def get_payment_url(conn, suffix \\ "") do
    path = Routes.cart_path(conn, :check_payment)

    if (conn.scheme == :http and conn.port == 80) or
         (conn.scheme == :https and conn.port == 443) do
      "#{conn.scheme}://#{conn.host}#{path}#{suffix}"
    else
      "#{conn.scheme}://#{conn.host}:#{conn.port}#{path}#{suffix}"
    end
  end

  def get_redirect("stripe", conn, %{body: %{"order" => order}}) do
    links = [Routes.stripe_path(conn, :index, order.id)]
    {:ok, links, order.id}
  end

  def get_redirect(provider, _conn, payment) do
    Books.Payment.get_redirect(provider, payment)
  end
end
