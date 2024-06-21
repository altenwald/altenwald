defmodule BooksWeb.CartControllerTest do
  use BooksWeb.ConnCase

  import Tesla.Mock

  alias Books.Cart.PaymentOption
  alias Books.Catalog

  defp clean_mailbox do
    receive do
      _ -> clean_mailbox()
    after
      0 ->
        :ok
    end
  end

  setup do
    clean_mailbox()

    mock_global(fn
      # mailchimp
      %{method: :post, url: "https://us6.api.mailchimp.com/3.0/lists/44ad6e0310/members"} ->
        json(%{"status" => "subscribed"})

      # geoip
      %{method: :get, url: "https://ipinfo.io/127.0.0.1"} ->
        json(%{"country" => "ES"})

      # create_payment
      %{method: :post, url: "https://api.sandbox.paypal.com/v1/payments/payment"} ->
        json(
          %{
            "links" => [
              %{"method" => "REDIRECT", "href" => "http://make-payment?token=PAYMENT_TOKEN"}
            ],
            "id" => "PAYMENT1"
          },
          status: 201
        )

      # show_payment_details
      %{method: :get, url: "https://api.sandbox.paypal.com/v1/payments/payment/PAYMENT1"} ->
        json(%{
          "state" => "created",
          "payer" => %{"payer_info" => %{"payer_id" => "A1", "email" => "test@test.com"}},
          "transactions" => [
            %{
              "related_resources" => [
                %{"sale" => %{"transaction_fee" => %{"currency" => "EUR", "value" => "0.52"}}}
              ]
            }
          ]
        })

      # execute_payment
      %{method: :post, url: "https://api.sandbox.paypal.com/v1/payments/payment/PAYMENT1/execute"} ->
        json(%{
          "state" => "approved",
          "transactions" => [
            %{
              "related_resources" => [
                %{"sale" => %{"transaction_fee" => %{"currency" => "EUR", "value" => "0.52"}}}
              ]
            }
          ]
        })

      # auth
      %{method: :post, url: "https://api.sandbox.paypal.com/v1/oauth2/token"} ->
        json(%{"access_token" => "AAA", "expires_in" => 1000})

      # invoice
      %{method: :post, url: "https://a123456.facturadirecta.com/api/invoices.xml"} ->
        text(%{})

      # mattermost message
      %{method: :post, url: "https://hooks.mattermost.com/posts"} ->
        json(%{})
    end)

    :ok
  end

  test "Add and remove items from cart", %{conn: conn} do
    book = Catalog.get_book_by_slug("erlang-i")
    [format | _] = book.formats

    conn = get(conn, Routes.cart_path(conn, :index))

    resp = html_response(conn, 200)

    assert [{_, _, ["El carrito está vacío."]} | _] = Floki.find(resp, "#cart-message")

    conn =
      conn
      |> recycle()
      |> put_req_header("referer", "/")
      |> get(Routes.cart_path(conn, :add, format.id))

    html_response(conn, 302)
    assert ["noindex"] == get_resp_header(conn, "x-robots-tag")

    conn =
      conn
      |> recycle()
      |> get(Routes.cart_path(conn, :index))

    resp = html_response(conn, 200)

    assert Floki.find(resp, "#cart-num-items")
           |> Floki.text()
           |> String.trim() == "1"

    conn =
      conn
      |> recycle()
      |> put_req_header("referer", "/")
      |> get(Routes.cart_path(conn, :rem, format.id))

    html_response(conn, 302)
    assert ["noindex"] == get_resp_header(conn, "x-robots-tag")

    conn =
      conn
      |> recycle()
      |> get(Routes.cart_path(conn, :index))

    resp = html_response(conn, 200)

    assert Floki.find(resp, "#cart-num-items")
           |> Floki.text()
           |> String.trim() == "0"
  end

  @payment_option "paypal"
  @buy_book "erlang-i"
  @download_file "/tmp/Erlang_OTP_v1_2ed.epub"
  @download_file_content "FILE"

  test "Add element, pay and download", %{conn: conn} do
    book = Catalog.get_book_by_slug(@buy_book)
    [format | _] = book.formats
    payment_option = PaymentOption.get_by_slug(@payment_option)

    assert :ok = Books.Cart.subscribe()

    Paypal.Auth.start_link([])

    conn = get(conn, Routes.cart_path(conn, :index))

    resp = html_response(conn, 200)

    assert_receive {:init, token, "127.0.0.1", :new}

    assert [{_, _, ["El carrito está vacío."]} | _] = Floki.find(resp, "#cart-message")

    conn =
      conn
      |> recycle()
      |> put_req_header("referer", "/")
      |> get(Routes.cart_path(conn, :add, format.id))

    html_response(conn, 302)
    assert ["noindex"] == get_resp_header(conn, "x-robots-tag")

    item = format.id
    assert_receive {:add_item, ^token, "127.0.0.1", ^item}
    assert_receive {:check_offers, ^token, "127.0.0.1", []}

    conn =
      conn
      |> recycle()
      |> get(Routes.cart_path(conn, :index))

    resp = html_response(conn, 200)
    %{title: title, subtitle: subtitle} = book
    %{price: price} = format
    price = Money.to_string(price)
    assert Floki.find(resp, "#cart-num-items") |> Floki.text() |> String.trim() == "1"
    assert Floki.find(resp, "h4.order.book-title") |> Floki.text() |> String.trim() == title
    assert Floki.find(resp, "p.order.book-subtitle") |> Floki.text() |> String.trim() == subtitle
    assert Floki.find(resp, ".item-quantity") |> Floki.text() |> String.trim() == "1"
    assert Floki.find(resp, "#order-total-price") |> Floki.text() |> String.trim() == price

    form = %{
      "order" => %{
        "first_name" => "Manuel",
        "last_name" => "Rubio",
        "email" => "manuel@altenwald.com",
        "payment_option_id" => payment_option.id,
        "accept_tos" => "true"
      }
    }

    conn =
      conn
      |> recycle()
      |> post(Routes.cart_path(conn, :payment), form)

    resp = html_response(conn, 302)
    assert resp =~ "http://make-payment"

    assert_receive {:process, ^token, "127.0.0.1", :valid}

    query_opts = %{
      "paymentId" => "PAYMENT1",
      "provider" => @payment_option,
      "token" => "PAYMENT_TOKEN"
    }

    conn =
      conn
      |> recycle()
      |> put_req_header("referer", "https://www.sandbox.paypal.com/PAYMENT1")
      |> get(Routes.cart_path(conn, :check_payment), query_opts)

    resp = html_response(conn, 200)
    assert [{_, _, ["Pago realizado"]} | _] = Floki.find(resp, ".inform h1")
    [{_, [{"id", _}, {"href", download_url} | _], _} | _] = Floki.find(resp, ".inform a")

    assert_receive {:paid, ^token, "127.0.0.1", _locale = "es"}
    assert_receive {:init, new_token, "127.0.0.1", :new} when new_token != token

    File.write!(@download_file, @download_file_content)

    conn =
      conn
      |> recycle()
      |> get(download_url)

    assert @download_file_content == response(conn, 200)

    filename = Path.basename(@download_file)
    assert_receive {:download, ^token, "127.0.0.1", ^filename}

    Paypal.Auth.stop()

    assert_receive {:plug_conn, :sent}
  end
end
