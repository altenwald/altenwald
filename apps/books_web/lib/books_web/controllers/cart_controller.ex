defmodule BooksWeb.CartController do
  use BooksWeb, :controller
  require Logger

  alias Books.Ads
  alias Books.{Cart, Payment, Shipping}
  alias Books.Cart.{Order, PaymentOption}

  @free_provider "4free"

  plug BooksWeb.SetOrder, except: ~w[
    change_payment_status
    payment
    check_payment
  ]a

  def index(conn, _params) do
    {id, conn} = BooksWeb.SetOrder.get_order_id(conn)
    order = Cart.get_order(id)
    changeset = Order.changeset(order, %{})

    payment_options =
      if Money.zero?(order.total_price) do
        [payment_option: Cart.PaymentOption.get_by_slug(@free_provider)]
      else
        [payment_options: PaymentOption.all()]
      end

    render(
      conn,
      default_opts(
        conn,
        order,
        [
          title: gettext("Cart"),
          changeset: changeset
        ] ++ payment_options
      )
    )
  end

  def discount(conn, params) do
    if offer = Ads.get_offer_by_code(params["offer"]["code"]) do
      {id, conn} = BooksWeb.SetOrder.get_order_id(conn)
      Cart.add_offer(id, offer)

      conn
      |> put_flash(:info, gettext("accepted code"))
      |> redirect(to: Routes.cart_path(conn, :index))
    else
      conn
      |> put_flash(:error, gettext("invalid code"))
      |> redirect(to: Routes.cart_path(conn, :index))
    end
  end

  def payment(conn, %_{slug: @free_provider}, order_id) do
    order = Cart.get_order(order_id)

    if Money.zero?(order.total_price) do
      info = %{
        "payer" => %{
          "payer_info" => %{
            "email" => order.email,
            "firt_name" => order.first_name,
            "last_name" => order.last_name
          }
        }
      }

      :ok = Cart.pay(order_id, info, conn.assigns[:locale])
      order = Cart.get_order(order_id)

      opts =
        default_opts(conn,
          title: gettext("Payment successfully"),
          hashid: order_id,
          files: Cart.get_files(order_id),
          preventa: Cart.presale?(order_id),
          order: order
        )

      conn
      |> put_session(:order_id, nil)
      |> render("paid.html", opts)
    else
      Logger.error(
        "error in payment: order #{order_id} hasn't payment method and it's not for free"
      )

      Cart.cancel(order_id)

      opts =
        default_opts(conn,
          title: gettext("Payment error"),
          hashid: nil,
          formats: nil
        )

      conn
      |> put_session(:order_id, nil)
      |> render("payment_error.html", opts)
    end
  end

  def payment(conn, %_{slug: provider}, order_id) do
    order = Cart.get_order(order_id)
    f = &BooksWeb.Payment.get_payment_url(conn, &1)
    build_payment = Payment.build_payment(provider, order, f, conn.assigns[:locale])

    with {:ok, payment} <- Payment.create_payment(provider, build_payment),
         {:ok, [link | _], token} <- BooksWeb.Payment.get_redirect(provider, conn, payment) do
      Cart.set_token(order_id, token)
      Cart.set_payment_id(order_id, payment.body["id"])

      conn
      |> put_session(:order_id, nil)
      |> redirect(external: link)
    else
      error ->
        Logger.error("error in payment: #{inspect(error)}")
        Cart.cancel(order_id)

        opts =
          default_opts(conn,
            title: gettext("Payment error"),
            hashid: nil,
            formats: nil
          )

        conn
        |> put_session(:order_id, nil)
        |> render("payment_error.html", opts)
    end
  end

  def payment(conn, params) do
    {id, conn} = BooksWeb.SetOrder.get_order_id(conn)
    amount = Shipping.get_amount(params["order"]["shipping_country"])
    params_order = Map.put(params["order"], "shipping_amount", amount)

    if Cart.process(id, params_order) do
      payment(conn, Cart.get_payment_option(id), id)
    else
      order = Cart.get_order(id)
      changeset = Order.changeset(order, params_order)

      changeset =
        case Ecto.Changeset.apply_action(changeset, :insert) do
          {:error, changeset} -> changeset
          {:ok, _order} -> changeset
        end

      payment_options =
        if Money.zero?(order.total_price) do
          [payment_option: Cart.PaymentOption.get_by_slug(@free_provider)]
        else
          [payment_options: PaymentOption.all()]
        end

      opts = [{:changeset, changeset} | payment_options]

      conn
      |> put_session(:order_id, id)
      |> put_flash(:error, gettext("Provide full data and accept the terms of service, please"))
      |> render("index.html", default_opts(order, opts))
    end
  end

  def check_payment(conn, %{"cancel" => _, "token" => token, "provider" => provider}) do
    Logger.error("order cancelled in #{provider} #{token}")

    if order_id = Cart.get_by_token(token) do
      Cart.cancel(order_id)
    end

    opts =
      default_opts(conn,
        title: gettext("Payment cancelled"),
        hashid: nil,
        formats: nil
      )

    render(conn, "payment_cancelled.html", opts)
  end

  def check_payment(conn, %{"token" => token, "provider" => provider}) do
    if order_id = Cart.get_by_token(token) do
      payment_id = Cart.get_payment_id(order_id)

      case Payment.check_payment(provider, payment_id) do
        {:ok, full_order} ->
          :ok = Cart.pay(order_id, full_order, conn.assigns[:locale])
          order = Cart.get_order(order_id)

          opts =
            default_opts(conn,
              title: gettext("Payment successfully"),
              hashid: order_id,
              files: Cart.get_files(order_id),
              preventa: Cart.presale?(order_id),
              order: order
            )

          conn
          |> put_session(:order_id, nil)
          |> render("paid.html", opts)

        {:error, :cancelled} ->
          Logger.error("order not found by #{provider} #{token} was cancelled")
          Cart.cancel(order_id)

          opts =
            default_opts(conn,
              title: gettext("Payment cancelled"),
              hashid: nil,
              formats: nil
            )

          conn
          |> put_session(:order_id, nil)
          |> render("payment_cancelled.html", opts)

        {:error, :notfound} ->
          Logger.error("order not found by #{provider} #{token}")

          opts =
            default_opts(conn,
              title: gettext("Payment not found"),
              token: token,
              hashid: nil,
              formats: nil
            )

          conn
          |> put_session(:order_id, nil)
          |> render("payment_not_found.html", opts)

        {:error, reason} ->
          Logger.error("order not found by #{provider} #{token}: #{inspect(reason)}")

          opts =
            default_opts(conn,
              title: gettext("Payment error"),
              hashid: nil,
              formats: nil
            )

          conn
          |> put_session(:order_id, nil)
          |> render("payment_error.html", opts)
      end
    else
      Logger.warning("not found token: #{token}")

      opts =
        default_opts(conn,
          title: gettext("Payment not found"),
          token: nil,
          hashid: nil,
          formats: nil
        )

      conn
      |> put_session(:order_id, nil)
      |> render("payment_not_found.html", opts)
    end
  end

  def change_payment_status(conn, %{"provider" => provider, "update" => _, "id" => id}) do
    Logger.info("[#{provider}] received update for request #{id}")

    case Payment.get_payment(provider, id) do
      {:ok, payment} -> Logger.info("[#{provider}] info: #{inspect(payment)}")
      error -> Logger.error("[#{provider}] info: #{inspect(error)}")
    end

    render(conn, "change_payment_status", status: "ok")
  end

  defp return_to(conn, params) do
    with nil <- params["return-to"],
         [] <- get_req_header(conn, "referer") do
      Routes.catalog_path(conn, :index)
    else
      [url] -> URI.new!(url).path
      path when is_binary(path) -> path
    end
  end

  defp rem_item(conn, format_id) do
    {order_id, conn} = BooksWeb.SetOrder.get_order_id(conn)
    Cart.rem_item(order_id, format_id)
    conn
  end

  def rem(conn, %{"format" => format_id} = params) do
    conn
    |> rem_item(format_id)
    |> put_resp_header("x-robots-tag", "noindex")
    |> redirect(to: return_to(conn, params))
  end

  defp add_item(conn, format_id) do
    {order_id, conn} = BooksWeb.SetOrder.get_order_id(conn)
    Cart.add_item(order_id, format_id)
    conn
  end

  defp add_items(conn, formats) do
    {order_id, conn} = BooksWeb.SetOrder.get_order_id(conn)
    Enum.each(formats, &Cart.add_item(order_id, &1.id))
    conn
  end

  def add(conn, %{"format" => format_id} = params) do
    conn
    |> add_item(format_id)
    |> put_flash(
      :info,
      gettext("Added successfully the item to the <a href='%{url}'>cart</a>",
        url: Routes.cart_path(conn, :index)
      )
    )
    |> put_resp_header("x-robots-tag", "noindex")
    |> redirect(to: return_to(conn, params))
  end

  def bundle(conn, %{"slug" => slug}) do
    bundle = Ads.get_bundle_by_slug!(slug)

    conn
    |> add_items(bundle.formats)
    |> put_resp_header("x-robots-tag", "noindex")
    |> redirect(to: Routes.cart_path(conn, :index))
  end

  def my_orders(conn, _params) do
    current_user = conn.assigns[:current_user]

    opts =
      default_opts(
        conn,
        title: gettext("My Orders"),
        my_orders: Cart.list_orders_by_email(current_user.email)
      )

    render(conn, "my_orders.html", opts)
  end

  def my_order(conn, %{"order_id" => order_id}) do
    current_user = conn.assigns[:current_user]
    order = Cart.ensure_get_order(order_id)

    if order != nil and order.email == current_user.email do
      opts =
        default_opts(
          conn,
          title: gettext("My Order: %{order_id}", order_id: order_id),
          my_order: order
        )

      render(conn, "my_order.html", opts)
    else
      raise BooksWeb.ErrorNotFound, message: gettext("Order not found")
    end
  end
end
