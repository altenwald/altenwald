defmodule Books.Schedulers.Order do
  use Cronex.Scheduler

  alias Books.Cart.Order

  every :day, at: "0:00" do
    Order.clean_orders()
  end
end
