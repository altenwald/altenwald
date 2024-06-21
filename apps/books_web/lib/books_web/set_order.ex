defmodule BooksWeb.SetOrder do
  import Plug.Conn
  require Logger
  alias Books.Cart

  def init(_opts), do: nil

  defp wait_for_order_starts(id, time_to_wait \\ 1_000)

  defp wait_for_order_starts(_id, time) when time <= 0, do: {:error, :cannot_be_found}

  defp wait_for_order_starts(id, time_to_wait) do
    if Cart.running?(id) do
      :ok
    else
      Process.sleep(100)
      wait_for_order_starts(id, time_to_wait - 100)
    end
  end

  defp cart_start(nil, conn, email) do
    order_id = Ecto.UUID.generate()
    {:ok, _pid} = Cart.start(order_id, BooksWeb.Endpoint.remote_ip(conn), email)
    wait_for_order_starts(order_id)
    put_session(conn, :order_id, order_id)
  end

  defp cart_start(order_id, conn, email) do
    unless Cart.running?(order_id) do
      {:ok, _pid} = Cart.start(order_id, BooksWeb.Endpoint.remote_ip(conn), email)
      wait_for_order_starts(order_id)
    end

    conn
  end

  defp can_be_run(_conn, nil), do: true

  defp can_be_run(conn, except_list) do
    conn.private.phoenix_action not in except_list
  end

  def call(conn, opts) do
    if can_be_run(conn, opts[:except]) do
      email =
        if current_user = conn.assigns[:current_user] do
          current_user.email
        end

      cart_start(get_session(conn, :order_id), conn, email)
    else
      conn
    end
  end

  def get_order_id(conn) do
    with {:one, id} when id != nil <- {:one, get_session(conn, :order_id)},
         {:two, order} when order != nil <- {:two, Cart.get_order(id)} do
      {id, conn}
    else
      {step, nil} when step in ~w[ one two ]a ->
        email =
          if current_user = conn.assigns[:current_user] do
            current_user.email
          end

        conn = cart_start(nil, conn, email)
        id = get_session(conn, :order_id)
        {id, conn}
    end
  end
end
