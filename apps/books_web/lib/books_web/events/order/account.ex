defmodule BooksWeb.Events.Order.Account do
  @moduledoc """
  Listen for paid orders, if the email in the order isn't belonging to an
  existing user it's creating it.
  """
  use GenServer

  alias Books.{Accounts, Cart}
  alias BooksWeb.Endpoint
  alias BooksWeb.Router.Helpers, as: Routes

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    Cart.subscribe()
    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:paid, order_id, _remote_ip, locale}, state) do
    order_id
    |> Cart.ensure_get_order()
    |> then(&maybe_register_user_by_order(&1.email, order_id, locale))

    {:noreply, state}
  end

  def handle_info(_event, state), do: {:noreply, state}

  defp random_password do
    data =
      Enum.to_list(?a..?z) ++
        Enum.to_list(?A..?Z) ++
        Enum.to_list(?0..?9) ++
        ~c"?!$%&/()=?@#[]{}-_+*.:,;"

    1..12
    |> Enum.map(fn _ -> Enum.random(data) end)
    |> to_string()
  end

  defp maybe_register_user_by_order(email, order_id, locale) do
    order = Cart.ensure_get_order(order_id)

    tags =
      order.items
      |> Stream.map(& &1.format.book)
      |> Stream.map(&Cart.get_tags_by_book/1)
      |> Stream.map(&MapSet.new/1)
      |> Enum.reduce(MapSet.new(), &MapSet.union/2)
      |> MapSet.to_list()

    if user = Accounts.get_user_by_email(email) do
      Accounts.update_purchase_tags(user, tags)
    else
      {:ok, user} =
        Accounts.register_user(%{
          "first_name" => order.first_name,
          "last_name" => order.last_name,
          "email" => email,
          "password" => random_password(),
          "lang" => locale,
          "mailling_tags" => tags
        })

      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(Endpoint, :edit, &1),
        locale
      )
    end
  end
end
