defmodule BooksWeb.CartHTML do
  use BooksWeb, :html
  use Countries.I18n
  require Logger

  def money(price, quantity), do: money(Money.multiply(price, quantity))

  def discount(price, nil), do: price
  def discount(price, {"percentage", pct}), do: Money.multiply(price, pct / 100)
  def discount(price, {"money", amount}), do: Money.subtract(price, amount)

  def countries do
    countries =
      for(c <- Countries.all(), do: {country(c.alpha2), c.alpha2})
      |> Enum.sort()

    [{"", ""} | countries]
  end

  def render("change_payment_status", %{status: status}) do
    status
  end

  defp exists_user?(email) do
    Books.Accounts.get_user_by_email(email) != nil
  end

  def translate("Card (Stripe)"), do: gettext("Card (Stripe)")
  def translate(other), do: other

  def translate_status(:new), do: gettext("new")
  def translate_status(:waiting), do: gettext("waiting")
  def translate_status(:paid), do: gettext("paid")
  def translate_status(:cancelled), do: gettext("cancelled")
  def translate_status(:"timed-out"), do: gettext("timed-out")
  def translate_status(:refunded), do: gettext("refunded")

  def translate_shipping_status(:"not-applicable"), do: gettext("not-applicable")
  def translate_shipping_status(:new), do: gettext("new")
  def translate_shipping_status(:preparing), do: gettext("preparing")
  def translate_shipping_status(:sent), do: gettext("sent")
  def translate_shipping_status(:received), do: gettext("received")

  defp get_num_items(order) do
    Enum.reduce(order.items, 0, fn item, acc ->
      acc + item.quantity
    end)
  end

  defp get_content(order) do
    if length(order.items) > 1 do
      [item1 | _] = order.items

      title =
        item1.format.book
        |> Books.Catalog.get_book_title()
        |> String.slice(0..20)

      title <> "..., ..."
    else
      [item] = order.items

      title =
        item.format.book
        |> Books.Catalog.get_book_title()
        |> String.slice(0..20)

      title <> "..."
    end
  end

  embed_templates "cart_html/*"
end
