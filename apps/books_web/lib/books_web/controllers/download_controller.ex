defmodule BooksWeb.DownloadController do
  use BooksWeb, :controller
  require Logger

  alias Books.Cart
  alias Books.Cart.Order

  plug :check_format
  plug :check_token

  def check_format(conn, _params) do
    if String.downcase(conn.params["format"]) in ~w[ pdf epub ] do
      conn
    else
      Logger.error("unknown format to download #{inspect(conn.params)}")

      Cart.notify({
        :download_error,
        conn.params["token"],
        BooksWeb.Endpoint.remote_ip(conn),
        :unknown_format,
        conn.params["format"]
      })

      raise BooksWeb.ErrorNotFound, message: gettext("book format not found")
    end
  end

  def check_token(conn, _params) do
    order_id = conn.params["token"]

    if Cart.running?(order_id) do
      if Cart.expired?(order_id) do
        Cart.notify({
          :download_error,
          order_id,
          BooksWeb.Endpoint.remote_ip(conn),
          :expired,
          nil
        })

        conn
        |> assign(:files, [])
        |> render("expired.html", default_opts(conn))
        |> halt()
      else
        assign(conn, :files, Cart.get_files(order_id))
      end
    else
      order = Cart.get_stored_order(order_id)

      if Order.expired?(order) do
        raise BooksWeb.ErrorNotFound, message: gettext("order expired")
      end

      assign(conn, :files, Order.get_files(order))
    end
  end

  @spec get_order(Order.t()) :: pos_integer()
  defp get_order(order) do
    String.to_integer(order)
  rescue
    ArgumentError -> 100
  end

  defp filename(files, order) do
    with base when base != nil <- Application.get_env(:books_web, :files_path),
         true <- order < length(files),
         %_{filename: filename} <- Enum.at(files, order) do
      Logger.info("downloading => #{filename}")
      Path.join(base, filename)
    else
      _ -> nil
    end
  end

  def download(conn, %{"token" => order_id, "order" => order_str}) do
    order = get_order(order_str)
    files = conn.assigns.files
    file_path = filename(files, order)
    Logger.debug("files => #{inspect(files)}")

    if is_nil(file_path) do
      Cart.notify({
        :download_error,
        order_id,
        BooksWeb.Endpoint.remote_ip(conn),
        :path,
        "invalid filepath order=#{order}"
      })

      Logger.error("cannot download, reason=path order=#{order} order_id=#{order_id}")
      raise BooksWeb.ErrorNotFound, message: gettext("file not found")
    end

    unless File.exists?(file_path) do
      Cart.notify({
        :download_error,
        order_id,
        BooksWeb.Endpoint.remote_ip(conn),
        :exists,
        file_path
      })

      Logger.error("cannot download, reason=exists #{file_path} not found!")
      raise BooksWeb.ErrorNotFound, message: gettext("file not found")
    end

    basename = Path.basename(file_path)
    Cart.notify({:download, order_id, BooksWeb.Endpoint.remote_ip(conn), basename})

    conn
    |> put_resp_content_type("application/octet-stream", "utf-8")
    |> put_resp_header(
      "content-disposition",
      ~s[attachment; filename="#{basename}"]
    )
    |> send_file(200, file_path)
  end
end
