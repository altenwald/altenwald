defmodule BooksWeb.CatalogControllerTest do
  use BooksWeb.ConnCase

  import Tesla.Mock

  setup do
    mock_global(fn
      %{method: :get, url: "http://api.ipstack.com/" <> _ip_and_query} ->
        json(%{"country_code" => "ES"})
    end)

    :ok
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, Routes.catalog_path(conn, :index))
    resp = html_response(conn, 200)

    assert Floki.find(resp, "p.book-title") |> Floki.text() =~ "Erlang/OTP Volumen I\n"
    assert Floki.find(resp, "p.book-title") |> Floki.text() =~ "Erlang/OTP Volumen II\n"

    assert Floki.find(resp, ".book-title-erlang-i") |> Floki.text() =~ "Erlang/OTP Volumen I"
    assert Floki.find(resp, ".book-subtitle-erlang-i") |> Floki.text() =~ "Un Mundo Concurrente"
    assert Floki.find(resp, ".book-title-erlang-ii") |> Floki.text() =~ "Erlang/OTP Volumen II"
    assert Floki.find(resp, ".book-subtitle-erlang-ii") |> Floki.text() =~ "Las Bases de OTP"
  end

  test "GET /book/erlang-i", %{conn: conn} do
    conn = get(conn, Routes.catalog_path(conn, :book, "erlang-i"))
    resp = html_response(conn, 200)
    assert Floki.find(resp, "#buy-digital-price") |> Floki.text() =~ "10,00 €"
    assert Floki.find(resp, "#buy-paper-price") |> Floki.text() =~ "20,00 €"
    assert Floki.find(resp, "#buy-paper-price-shipping") |> Floki.text() =~ "10,00 €"
  end
end
