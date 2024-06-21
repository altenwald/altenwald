defmodule BooksAdmin.CartController do
  use BooksAdmin, :controller
  alias Books.Cart

  def edit(conn, %{"id" => order_id}) do
    if order = Cart.get_stored_order(order_id) do
      render(conn, "edit.html",
        order: order,
        changeset: Cart.change_order(order),
        shipping_statuses: list_shipping_statuses(),
        title: gettext("Edit Order #%{order_id}", order_id: order_id)
      )
    else
      conn
      |> put_flash(:error, gettext("Cannot find the order"))
      |> redirect(to: Routes.cart_path(conn, :index))
    end
  end

  defp list_shipping_statuses do
    [
      {"", :"not-applicable"},
      {gettext("new"), :new},
      {gettext("preparing"), :preparing},
      {gettext("sent"), :sent},
      {gettext("received"), :received}
    ]
  end

  def update(conn, %{"id" => order_id, "order" => order}) do
    case Cart.change_shipping(order_id, order) do
      {:ok, _order} ->
        conn
        |> put_flash(:info, gettext("Order updated correctly"))
        |> redirect(to: Routes.cart_path(conn, :index))

      {:error, changeset} ->
        render(conn, "edit.html",
          order: changeset.data,
          changeset: changeset,
          shipping_statuses: list_shipping_statuses(),
          title: gettext("Edit Order #%{order_id}", order_id: order_id)
        )
    end
  end

  def show(conn, %{"id" => order_id}) do
    cond do
      order = Cart.get_order(order_id) ->
        render(conn, "show.html",
          order: order,
          title: gettext("Order #%{order_id}", order_id: order_id)
        )

      order = Cart.get_stored_order(order_id) ->
        render(conn, "show.html",
          order: order,
          title: gettext("Order #%{order_id}", order_id: order_id)
        )

      :else ->
        render(conn, "show.html",
          order: nil,
          title: gettext("Order not found")
        )
    end
  end

  def index(conn, params) do
    page = Cart.list_orders_paginated(params)
    render(conn, "index.html", page: page)
  end

  def stop(conn, %{"id" => order_id}) do
    if Cart.running?(order_id) do
      Cart.stop(order_id)

      conn
      |> put_flash(:info, gettext("Order stopped successfully!"))
      |> redirect(to: Routes.cart_path(conn, :index))
    else
      conn
      |> put_flash(:error, gettext("Cannot find the order"))
      |> redirect(to: Routes.cart_path(conn, :index))
    end
  end
end
