defmodule Books.Cart.Notifier.Balances do
  use GenServer
  require Logger
  alias Books.{Balances, Cart, Payment}

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    Cart.subscribe()
    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:paid, order_id, _remote_ip, _locale}, state) do
    order = Cart.ensure_get_order(order_id)

    if Money.zero?(order.total_price) do
      Logger.notice("free order #{order_id}, ignoring balances update")
    else
      target = order.payment_option.slug
      fee = Payment.get_payment_fee(target, order.payment_id)
      {{year, month, _}, _} = NaiveDateTime.to_erl(order.inserted_at)

      Balances.add_outcome(fee, length(order.items), month, year, target)

      if order.shipping? do
        Balances.add_income(
          order.shipping_total,
          order.shipping_items,
          month,
          year,
          nil,
          "shipping"
        )
      end

      for item <- order.items do
        Balances.add_income(item.total, item.quantity, month, year, item.format.book_id)
      end
    end

    {:noreply, state}
  end

  def handle_info(_event, state), do: {:noreply, state}
end
