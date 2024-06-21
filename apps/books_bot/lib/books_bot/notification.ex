defmodule BooksBot.Notification do
  @moduledoc """
  Notification module exists because we need to listen for some pubsub
  messages and we have no way to perform this action inside of
  `BooksBot.Action`, that module is performing the `init/1` function
  from the supervisor and not from the dispatcher.
  """
  require Logger
  use GenServer
  import BooksBot.Components, only: [escape_markdown: 1]
  alias Books.Cart
  alias Books.Payment
  alias Books.Schedulers.Stats

  if Mix.env() == :prod do
    @prefix ""
  else
    @prefix "⚠️ #{Mix.env()} ⚠️  \n"
  end

  def start_link([]), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl GenServer
  def init(_opts) do
    Cart.subscribe()
    Payment.subscribe()
    Stats.subscribe()
    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:error, provider, data}, state) do
    message = """
    🐛 Error:
    ```
    #{escape_markdown(inspect(data, pretty: true))}
    ```
    *Provider* #{to_string(provider)}
    """

    broadcast(message)
    {:noreply, state}
  end

  def handle_info({:paid, order_id, _remote_ip, _locale}, state) do
    order = Books.Cart.ensure_get_order(order_id)
    url = "https://altenwald.com/admin/cart/#{order.id}"

    message =
      if order.shipping? do
        """
        📚 *Vendido\\(s\\) libro\\(s\\)* \\([#{order.state}](#{url})\\)

        #{build_description(order)}
        #{build_address(order)}
        """
      else
        """
        📚 *Vendido\\(s\\) libro\\(s\\)* \\([#{order.state}](#{url})\\)

        #{build_description(order)}
        """
      end

    broadcast(message)
    {:noreply, state}
  end

  def handle_info({:processing, order_id, remote_ip}, state) do
    [
      "💰 Procesando pago",
      "",
      "*IP*: `#{escape_markdown(remote_ip)}`",
      "*Order ID*: #{url(order_id)}"
    ]
    |> Enum.join("  \n")
    |> broadcast()

    {:noreply, state}
  end

  def handle_info({:download_error, order_id, remote_ip, type, msg}, state) do
    [
      "🐞 Error *#{escape_markdown(type)}* -> _#{escape_markdown(inspect(msg))}_",
      "",
      "*IP*: `#{escape_markdown(remote_ip)}`",
      "*Order ID*: #{url(order_id)}"
    ]
    |> Enum.join("  \n")
    |> broadcast()

    {:noreply, state}
  end

  def handle_info({:download, order_id, remote_ip, file}, state) do
    [
      "💾 Downloaded *#{escape_markdown(file)}* from *#{escape_markdown(remote_ip)}*",
      "",
      "*IP*: `#{escape_markdown(remote_ip)}`",
      "*Order ID*: #{url(order_id)}"
    ]
    |> Enum.join("  \n")
    |> broadcast()

    {:noreply, state}
  end

  def handle_info({:stats, stats}, state) do
    [
      "📊 *Estadísticas de ventas*",
      "",
      "*Transacciones*",
      "",
      "Canceladas: #{stats.cancelled}",
      "Pagadas: #{stats.paid}",
      "",
      "Ingresos: #{escape_markdown(Money.to_string(stats.amount))}"
    ]
    |> Enum.join("  \n")
    |> broadcast()

    {:noreply, state}
  end

  def handle_info({:mailchimp, type, email}, state) do
    broadcast("✉️ 🐵 *#{type}* #{escape_markdown(email)}")
    {:noreply, state}
  end

  def handle_info(info, state) do
    Logger.warning("received unexpected message: #{inspect(info)}")
    {:noreply, state}
  end

  defp url(order_id) do
    "[#{order_id}](https://altenwald.com/admin/cart/#{order_id})"
  end

  defp broadcast(message, opts \\ [parse_mode: "MarkdownV2"]) do
    message = @prefix <> message
    send(BooksBot.Action.name(), {:send, message, opts})
  end

  defp build_description(order) do
    for item <- order.items do
      offer =
        if item.discount_display != "" do
          ["*Oferta*: #{escape_markdown(item.discount_display)}"]
        else
          []
        end

      [
        "*Title*: #{escape_markdown(Books.Catalog.get_book_title(item.format.book))}",
        "*Precio*: #{escape_markdown(Money.to_string(item.format.price))}",
        "*Unidades*: #{escape_markdown(item.quantity)}",
        "*Tipo*: #{escape_markdown(item.format.name)}",
        "*Medio de Pago*: #{escape_markdown(order.payment_option.name)}",
        "*Pagado*: #{escape_markdown(Money.to_string(item.total))}"
        | offer
      ]
      |> Enum.join("  \n")
    end
    |> Enum.join("\n\n")
  end

  defp build_address(order) do
    [
      "Se requiere envío a...\n",
      "*Nombre*: #{escape_markdown(order.first_name)} #{escape_markdown(order.last_name)}",
      "*Dirección*: #{escape_markdown(order.shipping_address)}",
      "*Código Postal*: #{escape_markdown(order.shipping_postal_code)}",
      "*Ciudad*: #{escape_markdown(order.shipping_city)}",
      "*Provincia*: #{escape_markdown(order.shipping_state)}",
      "*Código País*: #{escape_markdown(order.shipping_country)}",
      "*Teléfono*: #{escape_markdown(order.shipping_phone)}"
    ]
    |> Enum.join("  \n")
  end
end
