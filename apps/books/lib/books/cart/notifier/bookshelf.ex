defmodule Books.Cart.Notifier.Bookshelf do
  use GenServer
  require Logger
  alias Books.{Accounts, Cart}

  @time_to_resend 5_000

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    Cart.subscribe()
    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:paid, order_id, remote_ip, locale}, state) do
    with order when order != nil <- Cart.ensure_get_order(order_id),
         user when user != nil <- Accounts.get_user_by_email(order.email) do
      for %_{format: %_{name: name, book_id: book_id}} <- order.items, name != :paper do
        kind = :purchased
        attrs = [order_id: order.id]

        case Accounts.add_book_to_user(user.id, book_id, kind, attrs) do
          {:ok, _bookshelf_item} ->
            :ok

          {:error, changeset} ->
            Logger.error("error inserting: #{inspect(changeset.errors)}")
        end
      end
    else
      nil ->
        Logger.error("cannot assign order #{inspect(order_id)} to a user")
        Process.send_after(self(), {:paid, order_id, remote_ip, locale}, @time_to_resend)
    end

    {:noreply, state}
  end

  def handle_info(_event, state), do: {:noreply, state}
end
