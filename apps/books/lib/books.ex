defmodule Books do
  @moduledoc """
  Books keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias Books.Cart
  alias Books.Cart.Order

  defp money(nil), do: Money.to_string(Money.new(0))
  defp money(price), do: Money.to_string(price)

  defp money(price, quantity), do: money(Money.multiply(price, quantity))

  defp left(nil, len), do: String.duplicate(" ", len)

  defp left(str, len) do
    str
    |> to_string()
    |> String.slice(0, len)
    |> String.pad_trailing(len)
  end

  defp right(nil, len), do: String.duplicate(" ", len)

  defp right(str, len) do
    str
    |> String.slice(0, len)
    |> String.pad_leading(len)
  end

  @title_col 40
  @format_col 20
  @num_col 5
  @money_col 10

  @field_col 10
  @value_col 50

  defp separator(join \\ "-+-")

  defp separator(join) do
    [
      String.duplicate("-", @title_col),
      String.duplicate("-", @format_col),
      String.duplicate("-", @num_col),
      String.duplicate("-", @money_col),
      String.duplicate("-", @money_col)
    ]
    |> Enum.join(join)
    |> IO.puts()
  end

  defp field(name, value) do
    [
      right(name, @field_col),
      left(value, @value_col)
    ]
    |> Enum.join(": ")
    |> IO.puts()
  end

  def list_orders(start_date, idx \\ 2) when is_struct(start_date, Date) do
    start_date
    |> NaiveDateTime.new!(~T[00:00:00])
    |> Cart.list_orders_by_date()
    |> Enum.with_index(idx)
    |> Enum.each(fn {order, i} ->
      IO.puts("##{i}")
      show_order(order)
    end)
  end

  defp blue(str), do: "#{IO.ANSI.blue()}#{str}#{IO.ANSI.reset()}"
  defp green(str), do: "#{IO.ANSI.green()}#{str}#{IO.ANSI.reset()}"
  defp red(str), do: "#{IO.ANSI.red()}#{str}#{IO.ANSI.reset()}"

  defp state(:paid), do: green("paid")
  defp state(:cancelled), do: red("cancelled")
  defp state(other), do: blue(other)

  defp payment_option(nil), do: "-none-"
  defp payment_option(payment_option) when is_struct(payment_option), do: payment_option.name

  defp date_to_string(nil), do: "-none-"

  defp date_to_string(naive_date_time) when is_struct(naive_date_time, NaiveDateTime) do
    NaiveDateTime.to_date(naive_date_time)
    |> date_to_string()
  end

  defp date_to_string(date) when is_struct(date, Date) do
    to_string(date)
  end

  def show_order(order_id) when is_binary(order_id) do
    with nil <- Books.Cart.get_order(order_id),
         nil <- Books.Cart.get_stored_order(order_id) do
      IO.puts("#{IO.ANSI.red()}Not found!#{IO.ANSI.reset()}")
    else
      %Order{} = order ->
        show_order(order)
    end
  end

  def show_order(%Order{} = order) do
    separator("---")
    field "Order", order.id
    field "Date", date_to_string(order.inserted_at)
    field "State", state(order.state)
    field "Presale?", if(order.presale?, do: blue("Yes"), else: "No")
    field "Payed By", payment_option(order.payment_option)
    field "Name", order.first_name
    field "Surname", order.last_name
    field "Country", "[#{order.country}] #{Books.Flag.get_utf8_by_code(order.country)}"

    if order.shipping? do
      field "Address", order.shipping_address
      field "City", order.shipping_city
      field "Zip", order.shipping_postal_code
      field "State", order.shipping_state
      field "Country", order.shipping_country
      field "Phone", order.shipping_phone
    end

    separator("---")

    [
      left("Libro", @title_col),
      left("Formato", @format_col),
      left("Items", @num_col),
      left("Precio", @money_col),
      left("Total", @money_col)
    ]
    |> Enum.join(" | ")
    |> IO.puts()

    separator()

    for item <- order.items do
      format = item.format
      book = format.book
      book_title = left(book.title, 40)
      book_subtitle = book.subtitle
      format_name = format.name
      price = money(format.price)
      total = money(format.price, item.quantity)
      item_quantity = String.pad_leading(to_string(item.quantity), 2)

      [
        left(book_title, @title_col),
        left(format_name, @format_col),
        right(item_quantity, @num_col),
        right(price, @money_col),
        right(total, @money_col)
      ]
      |> Enum.join(" | ")
      |> IO.puts()

      [
        left(book_subtitle, @title_col),
        left("", @format_col),
        right("", @num_col),
        right("", @money_col),
        right("", @money_col)
      ]
      |> Enum.join(" | ")
      |> IO.puts()

      for offer <- order.offers, apply_on <- offer.applies, apply_on.id == item.format_id do
        offer_name = offer.name
        item_discount_display = item.discount_display
        item_discount_total = money(item.discount_total)

        [
          left(offer_name, @title_col + 3 + @format_col + 3 + @num_col),
          right(item_discount_display, @money_col),
          right(item_discount_total, @money_col)
        ]
        |> Enum.join(" | ")
        |> IO.puts()
      end
    end

    if order.shipping? do
      separator()
      order_shipping_items = to_string(order.shipping_items)
      order_shipping_subtotal = to_string(order.shipping_subtotal)

      [
        right("Gastos de envío", @title_col + 3 + @format_col + 3 + @num_col),
        right(order_shipping_items, @money_col),
        right(order_shipping_subtotal, @money_col)
      ]
      |> Enum.join(" | ")
      |> IO.puts()

      unless Money.zero?(order.shipping_discount) do
        order_shipping_discount = to_string(order.shipping_discount)

        [
          right(
            "Descuento de envío",
            @title_col + 3 + @format_col + 3 + @num_col + 3 + @money_col
          ),
          right(order_shipping_discount, @money_col)
        ]
        |> Enum.join(" | ")
        |> IO.puts()
      end
    end

    separator("-+-")
    order_total_price = to_string(order.total_price)

    [
      right("Total (IVA incl.)", @title_col + 3 + @format_col + 3 + @num_col + 3 + @money_col),
      right(order_total_price, @money_col)
    ]
    |> Enum.join(" | ")
    |> IO.puts()
  end
end
