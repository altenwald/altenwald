defmodule Books.Schedulers.Stats do
  use Cronex.Scheduler
  require Logger

  alias Books.Cart

  @pubsub Books.PubSub
  @topic "stats"

  @resend 7 * 24 * 3600

  every :monday, at: "9:00" do
    generate_stats()
  end

  def subscribe do
    :ok = Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  def generate_stats do
    from_date =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(@resend * -1)

    stats =
      from_date
      |> Cart.list_orders_by_date()
      |> Enum.reduce(%{paid: 0, cancelled: 0, amount: Money.new(0)}, fn order, acc ->
        case order.state do
          :paid ->
            acc
            |> Map.update!(:paid, &(&1 + 1))
            |> Map.update!(:amount, &Money.add(&1, order.total_price))

          :cancelled ->
            Map.update!(acc, :cancelled, &(&1 + 1))
        end
      end)

    Logger.debug("stats => #{inspect(stats)}")
    Phoenix.PubSub.broadcast(@pubsub, @topic, {:stats, stats})
  end
end
