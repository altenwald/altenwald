defmodule BooksWeb.CartHelpers do
  alias Books.Cart.Order

  def num_items(nil), do: 0

  def num_items(%Order{id: order_id}) do
    Books.Cart.get_num_items(order_id)
  end
end
