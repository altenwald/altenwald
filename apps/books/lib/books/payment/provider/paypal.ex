defmodule Books.Payment.Provider.Paypal do
  use Books.Payment
  require Logger

  alias Books.Money, as: AwMoney

  defp address(order) do
    %{
      "line1" => order.shipping_address,
      "city" => order.shipping_city,
      "country_code" => order.shipping_country,
      "postal_code" => order.shipping_postal_code,
      "state" => order.shipping_state
    }
  end

  defp application_context(shipping_preference, locale \\ "es-ES") do
    %{
      "brand_name" => "Altenwald Books",
      "locale" => locale,
      "landing_page" => "billing",
      "shipping_preference" => shipping_preference,
      "user_action" => "commit"
    }
  end

  defp item_list(order) do
    for item <- order.items do
      %{
        "name" => item.format.book.title,
        "quantity" => Integer.to_string(item.quantity),
        "price" => item.price,
        "tax" => item.tax_price,
        "currency" => Books.Money.currency()
      }
    end
  end

  @impl Payment
  def build_payment(order, url_funct, _locale) do
    return_url = url_funct.("?provider=paypal")
    cancel_url = url_funct.("?cancel&provider=paypal")

    if order.shipping? do
      details = %{
        "shipping" => order.shipping_total,
        "subtotal" => order.items_subtotal,
        "tax" => order.tax
      }

      transaction = [
        %{
          "amount" => %{
            "currency" => AwMoney.currency(),
            "details" => details,
            "total" => order.total_price
          },
          "item_list" => %{"items" => item_list(order), "shipping_address" => address(order)}
        }
      ]

      application_context = application_context("set_provided_address")

      %{
        "intent" => "sale",
        "application_context" => application_context,
        "payer" => %{
          "payment_method" => "paypal",
          "payer_info" => %{"email" => order.email, "billing_address" => address(order)}
        },
        "transactions" => transaction,
        "redirect_urls" => %{"return_url" => return_url, "cancel_url" => cancel_url}
      }
    else
      details = %{"subtotal" => order.items_subtotal, "tax" => order.tax}

      transaction = [
        %{
          "amount" => %{
            "currency" => AwMoney.currency(),
            "details" => details,
            "total" => order.total_price
          },
          "item_list" => %{"items" => item_list(order)}
        }
      ]

      application_context = application_context("no_shipping")

      %{
        "intent" => "sale",
        "application_context" => application_context,
        "payer" => %{"payment_method" => "paypal", "payer_info" => %{"email" => order.email}},
        "transactions" => transaction,
        "redirect_urls" => %{"return_url" => return_url, "cancel_url" => cancel_url}
      }
    end
  end

  @impl Payment
  def get_payment(payment_id) do
    case Paypal.show_payment_details(payment_id) do
      {:ok, resp} -> {:ok, resp.body}
      {:error, _} = error -> error
    end
  end

  @impl Payment
  def check_payment(paymentId) do
    with {:step1, {:ok, p1}} <- {:step1, Paypal.show_payment_details(paymentId)},
         {:step2, 200, p1} <- {:step2, p1.status, p1},
         {:step3, "created", p1} <- {:step3, p1.body["state"], p1},
         {:step4, payer_id, _p1} <- {:step4, p1.body["payer"]["payer_info"]["payer_id"], p1},
         {:step5, {:ok, p2}} <- {:step5, Paypal.execute_payment(paymentId, payer_id)},
         {:step6, 200, p2} <- {:step6, p2.status, p2},
         {:step7, "approved", p2} <- {:step7, p2.body["state"], p2} do
      {:ok, p2.body}
    else
      error ->
        Logger.error("check_payment error => #{inspect(error)}")
        {:error, :notfound}
    end
  end

  @impl Payment
  def create_payment(payment) do
    case Paypal.create_payment(payment) do
      {:ok, %{status: 201}} = result -> result
      {:ok, resp} -> {:error, resp.body}
      {:error, _} = error -> error
    end
  end

  @impl Payment
  def get_redirect(payment) do
    Logger.debug("payment => #{inspect(payment)}")
    links = for link <- payment.body["links"], link["method"] == "REDIRECT", do: link["href"]

    token =
      links
      |> List.first()
      |> URI.parse()
      |> Map.get(:query)
      |> URI.decode_query()
      |> Map.get("token")

    {:ok, links, token}
  end

  @impl Payment
  def get_payment_fee(payment_id) do
    {:ok, pay_info} = get_payment(payment_id)

    pay_info
    |> Access.get("transactions")
    |> hd()
    |> Access.get("related_resources")
    |> hd()
    |> Access.get("sale")
    |> Access.get("transaction_fee")
    |> Books.Money.parse()
  end
end
