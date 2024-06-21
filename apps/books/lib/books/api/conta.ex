defmodule Books.Api.Conta do
  use Tesla

  require Logger

  alias Books.Cart.OrderItem
  alias Books.Cart.Order
  alias Books.{Catalog, Payment}

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:books, :conta_base_url))
  plug(Tesla.Middleware.BearerAuth, token: Application.get_env(:books, :conta_api_key))

  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])
  plug(Tesla.Middleware.JSON)

  def run(%Order{} = order) do
    costs = Payment.get_payment_fee(order.payment_option.slug, order.payment_id)
    details = [
      Enum.map(order.items, &product_detail/1),
      maybe_shipping_detail(order)
    ] |> List.flatten()

    data = %{
      "invoice_date" => NaiveDateTime.to_date(order.inserted_at),
      "destination_country" => order.country,
      "total_price" => order.total_price.amount,
      "payment_method" => order.payment_option.slug,
      "costs" => costs.amount,
      "details" => details
    }

    Logger.debug("conta data #{inspect(data)}")

    post("/run", data)
  end

  defp product_detail(%OrderItem{discount_percentage: 0} = item) do
    [
      %{
        "description" => Catalog.get_full_book_title(item.format.book),
        "price" => Money.multiply(item.format.price, item.quantity).amount,
        "units" => item.quantity,
        "account" => "income"
      }
    ]
  end

  defp product_detail(%OrderItem{} = item) do
    product_detail(%OrderItem{item | discount_percentage: 0}) ++
    [
      %{
        "description" => "#{item.discount_percentage}% descuento",
        "price" => Money.multiply(item.discount_total, item.quantity).amount,
        "units" => 1,
        "account" => "expense"
      }
    ]
  end

  defp maybe_shipping_detail(%Order{shipping?: true, shipping_discount: %Money{amount: 0}} = order) do
    [
      %{
        "description" => "Transporte / Shipping",
        "price" => order.shipping_amount.amount,
        "units" => 1,
        "account" => "income"
      }
    ]
  end

  defp maybe_shipping_detail(%Order{shipping?: true} = order) do
    maybe_shipping_detail(%Order{order | shipping_discount: %Money{amount: 0}}) ++
    [
      %{
        "description" => "Descuento en envío",
        "price" => order.shipping_discount.amount,
        "units" => 1,
        "account_name" => "expense"
      }
    ]
  end

  defp maybe_shipping_detail(%Order{shipping?: false}), do: []
end
