defmodule BooksAdmin.CartChannel do
  use BooksAdmin, :channel
  require Logger

  alias Books.{Cart, Flag}
  alias BooksAdmin.Router.Helpers, as: Routes

  # Max age 24 hours (in seconds)
  @max_age 86_400
  @salt "---"

  # :flag_white:
  @default_flag "&#127987;"

  @default_url_prefix "/admin"

  def join("books:admin:cart", _params, %_{assigns: %{token: token}} = socket) do
    case Phoenix.Token.verify(socket, @salt, token, max_age: @max_age) do
      {:ok, cookie} ->
        {:ok, assign(socket, :token, cookie)}

      {:error, reason} ->
        Logger.error("cannot connect (token=#{inspect(token)}): #{inspect(reason)}")
        {:error, reason}
    end
  end

  def join(other, params, _socket) do
    Logger.error("cannot connect: other=#{inspect(other)} params=#{inspect(params)}")
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("reload", %{"uri" => "/admin"}, socket) do
    {orders, new_orders} = get_orders(socket)
    {:reply, {:ok, %{orders: orders, summary: new_orders}}, socket}
  end

  def get_orders(socket) do
    url_prefix = Application.get_env(:books_admin, :url_prefix, @default_url_prefix)

    {orders, new_orders} =
      Cart.get_active_orders()
      |> Enum.map(fn order ->
        country = String.downcase(order.country || "")

        %{
          "id" => order.id,
          "url" => url_prefix <> Routes.cart_path(socket, :show, order.id),
          "remote_ip" => order.remote_ip,
          "flag" => Flag.get_by_code(country) || @default_flag,
          "country" => country,
          "total_price" => order.total_price,
          "state" => to_string(order.state),
          "shipping" => order.shipping?
        }
      end)
      |> Enum.split_with(&(&1["state"] != "new" or not Money.zero?(&1["total_price"])))

    new_orders =
      new_orders
      |> Enum.reduce(%{}, fn order, acc ->
        country = order["country"]
        flag = Flag.get_by_code(country) || @default_flag
        update = fn %{"count" => count} = data -> Map.put(data, "count", count + 1) end
        Map.update(acc, country, %{"count" => 1, "flag" => flag}, update)
      end)
      |> Enum.map(fn {country, data} -> Map.put(data, "country", country) end)

    {orders, new_orders}
  end
end
