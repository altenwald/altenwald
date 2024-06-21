defmodule Books.Cart.Notifier.Logger do
  use GenServer
  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    Books.Cart.subscribe()
    {:ok, nil}
  end

  @impl GenServer
  def handle_info(event, state) do
    Logger.info("event => #{inspect(event)}")
    {:noreply, state}
  end
end
