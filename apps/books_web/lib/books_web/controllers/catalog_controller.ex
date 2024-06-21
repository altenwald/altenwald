defmodule BooksWeb.CatalogController do
  use BooksWeb, :controller
  require Logger

  alias Books.Catalog
  alias Books.Engagement

  plug :book_slug when action in [:book]

  defp book_slug(conn, _params) do
    Logger.debug("conn => #{inspect(conn)}")

    if book = Catalog.get_book_by_slug(conn.params["book_slug"]) do
      assign(conn, :book, book)
    else
      raise BooksWeb.ErrorNotFound, message: gettext("book not found")
    end
  end

  defp carousel(conn) do
    for item <- Books.Ads.list_ads_carousel(),
        item.enable and (item.book != nil or item.bundle != nil) do
      case item.type do
        :book ->
          %{
            image: item.image,
            link: Routes.catalog_path(conn, :book, item.book.slug),
            caption: Catalog.get_full_book_title(item.book)
          }

        :bundle ->
          %{
            image: item.image,
            link: Routes.cart_path(conn, :bundle, item.bundle.slug),
            caption: item.bundle.description
          }
      end
    end
  end

  def index(conn, %{"book_lang" => lang}) when lang in ~w[es en] do
    books =
      Catalog.list_books()
      |> Enum.filter(&(&1.lang == lang))

    render(
      conn,
      "index.html",
      default_opts(conn,
        books: books,
        book_lang: lang,
        carousel: carousel(conn)
      )
    )
  end

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      default_opts(conn,
        books: Catalog.list_books(),
        book_lang: nil,
        carousel: carousel(conn)
      )
    )
  end

  def new_subscription(nil, _), do: Engagement.new_subscription()

  def new_subscription(user, tags) do
    if tags -- user.mailling_tags == [] do
      false
    else
      Engagement.new_subscription(%{"email" => user.email})
    end
  end

  def book(conn, %{"book_slug" => _slug}) do
    book = conn.assigns.book
    tags = Engagement.get_tags_by_book(book)
    subscribe = new_subscription(conn.assigns[:current_user], tags)

    nav_entries = [
      %{id: "description", name: gettext("Description")},
      %{id: "info", name: gettext("Information")},
      %{id: "content", name: gettext("Content")},
      %{id: "author", name: gettext("Author")}
    ]

    render(
      conn,
      "book.html",
      default_opts(conn,
        link: "libro",
        subscribe: subscribe,
        nav_entries: nav_entries,
        book: book,
        ebook_shop_items: Enum.filter(book.shop_links, &(&1.type == :digital)),
        book_shop_items: Enum.filter(book.shop_links, &(&1.type == :paper))
      )
    )
  end

  def subscribe(conn, %{"book_slug" => book_slug, "subscribe" => params}) do
    unless book = Catalog.get_book_by_slug(book_slug) do
      raise BooksWeb.ErrorNotFound, message: gettext("Book not found")
    end

    case Engagement.new_subscription(params) do
      {:ok, subscribe} ->
        tags = Engagement.get_tags_by_book(book)

        if Engagement.save(subscribe, tags, conn.assigns[:locale]) do
          opts = default_opts(conn, link: "libro", subscribe: false, book: book)

          conn
          |> put_flash(:info, gettext("You has been subscribed successfully."))
          |> render("book.html", opts)
        else
          opts =
            default_opts(conn,
              link: "libro",
              subscribe: Engagement.new_subscription(),
              book: book
            )

          conn
          |> put_flash(:error, gettext("An error happened trying to subscribe. Try again later."))
          |> render("book.html", opts)
        end

      {:error, changeset} ->
        opts = default_opts(conn, link: "libro", subscribe: changeset, book: book)

        conn
        |> put_flash(
          :error,
          gettext("An error happened trying to subscribe. Maybe invalid name or email?")
        )
        |> render("book.html", opts)
    end
  end
end
