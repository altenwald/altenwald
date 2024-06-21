defmodule BooksAdmin.CartHTML do
  use BooksAdmin, :html
  import BooksAdmin.PaginationComponent
  alias Books.Cart

  def money(nil), do: Money.to_string(Money.new(0))
  def money(price), do: Money.to_string(price)

  def money(price, quantity), do: money(Money.multiply(price, quantity))

  def translate_status(:new), do: gettext("new")
  def translate_status(:waiting), do: gettext("waiting")
  def translate_status(:paid), do: gettext("paid")
  def translate_status(:cancelled), do: gettext("cancelled")
  def translate_status(:"timed-out"), do: gettext("timed-out")
  def translate_status(:refunded), do: gettext("refunded")

  def get_payment_option(nil), do: gettext("Not defined")
  def get_payment_option(%_{name: name}), do: name

  defp get_num_items(order) do
    Enum.reduce(order.items, 0, fn item, acc ->
      acc + item.quantity
    end)
  end

  defp get_full_content(%_{items: []}), do: "No items"

  defp get_full_content(%_{items: items}) do
    Enum.map_join(items, ", ", &Books.Catalog.get_full_book_title(&1.format.book))
  end

  defp get_content(%_{items: [item, _ | _]}) do
    title =
      item.format.book
      |> Books.Catalog.get_book_title()
      |> String.slice(0..60)

    title <> "..., ..."
  end

  defp get_content(%_{items: [item | _]}) do
    title =
      item.format.book
      |> Books.Catalog.get_book_title()
      |> String.slice(0..60)

    title <> "..."
  end

  defp get_content(%_{items: []}) do
    gettext("No items")
  end

  defp get_date(nil), do: gettext("Not defined")

  defp get_date(date_time) do
    date = NaiveDateTime.to_date(date_time)
    time = NaiveDateTime.to_time(date_time)
    hour = String.pad_leading(to_string(time.hour), 2, "0")
    minute = String.pad_leading(to_string(time.minute), 2, "0")
    "#{date} #{hour}:#{minute}"
  end

  embed_templates("cart_html/*")
end
