defmodule Books.Cart.Notifier.Conta do
  use GenServer

  require Logger

  alias Books.Api.Conta
  alias Books.Cart

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    Cart.subscribe()
    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:paid, order_id, _remote_ip, _locale}, state) do
    order_id
    |> Cart.ensure_get_order()
    |> Conta.run()
    |> case do
      {:ok, %_{status: code, body: body}} when code > 299 ->
        Logger.error("conta request #{inspect(order_id)} reason #{inspect(body)}")

      {:error, reason} ->
        Logger.error("conta request #{inspect(order_id)} reason #{inspect(reason)}")

      {:ok, %_{status: 200}} ->
        Logger.info("conta accepted #{order_id}")
    end

    {:noreply, state}
  end

  def handle_info(_event, state), do: {:noreply, state}
end
