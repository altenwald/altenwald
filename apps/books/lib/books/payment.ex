defmodule Books.Payment do
  import Books.Payment.Backend

  alias Books.Cart.Order

  @pubsub Books.PubSub
  @topic "payment"

  @callback build_payment(Order.t(), (String.t() -> String.t()), String.t()) :: map()
  @callback check_payment(String.t()) :: {:ok, map()} | {:error, atom()}
  @callback get_payment(String.t()) :: {:ok, map()} | {:error, atom()}
  @callback create_payment(map()) :: {:ok, map()} | {:error, atom()}
  @callback get_redirect(map()) :: {:ok, [String.t()], String.t()} | {:error, atom()}
  @callback get_payment_fee(String.t()) :: Money.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Books.Payment
      alias Books.Payment
    end
  end

  def subscribe do
    :ok = Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  def notify(event, provider) when is_tuple(event) do
    event
    |> Tuple.insert_at(1, provider)
    |> then(&Phoenix.PubSub.broadcast(@pubsub, @topic, &1))

    event
  end

  def notify(event, _provider), do: event

  backend(:build_payment, [order, url_funct, locale])
  backend(:check_payment, [payment_id])
  backend(:get_payment, [payment_id])
  backend(:create_payment, [payment])
  backend(:get_redirect, [links])
  backend(:get_payment_fee, [payment_id])
end
