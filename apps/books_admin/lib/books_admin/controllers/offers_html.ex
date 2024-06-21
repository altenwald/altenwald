defmodule BooksAdmin.OffersHTML do
  use BooksAdmin, :html
  import BooksAdmin.PaginationComponent

  defp get_discount(:money, discount), do: to_string(Money.new(discount))
  defp get_discount(:percentage, discount), do: "items #{discount}%"
  defp get_discount(:shipping, discount), do: "shipping #{discount}%"

  defp get_expiration(nil), do: gettext("No expiration")

  defp get_expiration(date_time) do
    date = NaiveDateTime.to_date(date_time)
    time = NaiveDateTime.to_time(date_time)
    hour = String.pad_leading(to_string(time.hour), 2, "0")
    minute = String.pad_leading(to_string(time.minute), 2, "0")
    "#{date} #{hour}:#{minute}"
  end

  embed_templates("offers_html/*")
end
