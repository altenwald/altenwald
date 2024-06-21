defmodule BooksAdmin.Events.CartEvent do
  @moduledoc """
  Listen for updates in the cart and send them to the websocket channel.
  """
  use GenServer

  alias Books.{Cart, Flag}
  alias BooksAdmin.Router.Helpers, as: Routes

  # :flag_white:
  @default_flag "&#127987;"

  @default_url_prefix "/admin"

  @topic "books:admin:cart"

  def start_link([endpoint]) do
    GenServer.start_link(__MODULE__, [endpoint], name: __MODULE__)
  end

  @impl GenServer
  def init([endpoint]) do
    Cart.subscribe()
    {:ok, endpoint}
  end

  @impl GenServer
  def handle_info(event, state) do
    process_event(event, state)
    {:noreply, state}
  end

  defp process_event({:init, order_id, _remote_ip, :new}, endpoint) do
    order = Cart.get_order(order_id)
    country = String.downcase(order.country || "")

    endpoint.broadcast(@topic, "inc-summary", %{
      "flag" => Flag.get_by_code(country) || @default_flag,
      "country" => country,
      "total_price" => "0.00",
      "state" => "new",
      "shipping" => false
    })
  end

  defp process_event({event_name, order_id, _remote_ip}, endpoint)
       when event_name in [:drop, :cancelled] do
    order = Cart.get_order(order_id)

    if order.state != "new" or not Money.zero?(order.total_price) do
      endpoint.broadcast(@topic, "remove", %{
        "id" => order_id
      })
    else
      country = String.downcase(order.country || "")

      endpoint.broadcast(@topic, "dec-summary", %{
        "flag" => Flag.get_by_code(country) || @default_flag,
        "country" => country
      })
    end
  end

  defp process_event({:add_item, order_id, remote_ip, _item}, endpoint) do
    order = Cart.get_order(order_id)
    country = String.downcase(order.country || "")
    url_prefix = Application.get_env(:books_admin, :url_prefix, @default_url_prefix)

    endpoint.broadcast(@topic, "update", %{
      "id" => order_id,
      "url" => url_prefix <> Routes.cart_path(endpoint, :show, order.id),
      "remote_ip" => remote_ip,
      "flag" => Flag.get_by_code(country) || @default_flag,
      "country" => country,
      "total_price" => order.total_price,
      "state" => order.state,
      "shipping" => order.shipping?
    })
  end

  defp process_event({:rem_item, order_id, remote_ip, _item}, endpoint) do
    order = Cart.get_order(order_id)
    country = String.downcase(order.country || "")

    if Money.zero?(order.total_price) do
      endpoint.broadcast(@topic, "remove", %{
        "id" => order_id
      })
    else
      endpoint.broadcast(@topic, "update", %{
        "id" => order_id,
        "remote_ip" => remote_ip,
        "flag" => Flag.get_by_code(country) || @default_flag,
        "total_price" => order.total_price,
        "state" => order.state,
        "shipping" => order.shipping?
      })
    end
  end

  defp process_event(_event, _endpoint), do: :ok
end
