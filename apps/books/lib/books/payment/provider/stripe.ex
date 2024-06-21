defmodule Books.Payment.Provider.Stripe do
  use Books.Payment
  require Logger

  alias Books.Cart
  alias Books.Cart.Order

  @impl Payment
  def build_payment(order, _f, _locale), do: order

  @impl Payment
  def get_payment(payment_id) do
    case Stripe.get_charge(payment_id) do
      {:ok, %{body: %{"balance_transaction" => txn}}} ->
        case Stripe.get_transaction(txn) do
          {:ok, resp} -> {:ok, resp.body}
          {:error, _} = error -> error
        end

      {:error, _} = error ->
        error
    end
  end

  @impl Payment
  def check_payment(token) do
    description = "Altenwald"

    with {:step0, order_id} <- {:step0, Cart.get_by_token(token)},
         {:step1, %Order{} = order} <- {:step1, Cart.get_order(order_id)},
         {:step2, %Money{amount: amount, currency: currency}} <- {:step2, order.total_price},
         {:step3, %{"id" => _} = result} <-
           {:step3, Stripe.charges(amount, currency, description, token)} do
      Logger.info("result => #{inspect(result)}")
      Cart.set_payment_id(order_id, result["id"])
      {:ok, result}
    else
      {:step3, %{"error" => _} = error} ->
        Logger.error("error in stripe payment: #{inspect(error)}")
        {:error, error}

      error ->
        Logger.error("check_payment error => #{inspect(error)}")
        {:error, :notfound}
    end
  end

  @impl Payment
  def create_payment(order), do: {:ok, %{body: %{"id" => order.id, "order" => order}}}

  @impl Payment
  def get_redirect(_payment), do: {:error, nil}

  @impl Payment
  def get_payment_fee(payment_id) do
    {:ok, pay_info} = get_payment(payment_id)
    Money.new(pay_info["fee"] || 0)
  end
end
