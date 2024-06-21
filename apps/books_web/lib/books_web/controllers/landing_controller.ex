defmodule BooksWeb.LandingController do
  use BooksWeb, :controller

  alias Books.{Catalog, Landings}
  alias Books.Engagement

  plug :put_layout, html: {BooksWeb.Layouts, :landing}
  plug :put_root_layout, false

  def show(conn, %{"slug" => slug}) do
    case Landings.get_by_slug(slug) do
      %_{slugs: [^slug | _]} = landing ->
        to_render(conn, landing, Engagement.new_subscription())

      %_{slugs: [main_slug | _]} ->
        conn
        |> put_status(:moved_permanently)
        |> redirect(to: Path.join(["/", main_slug]))

      nil ->
        raise BooksWeb.ErrorNotFound, message: gettext("landing page not found")
    end
  end

  def subscribe(conn, %{"slug" => slug, "subscribe" => params}) do
    unless landing = Landings.get_by_slug(slug) do
      raise BooksWeb.ErrorNotFound, message: gettext("landing page not found")
    end

    case Engagement.new_subscription(params) do
      {:ok, subscribe} ->
        tags = Engagement.get_tags_by_book(landing.book)

        if Engagement.save(subscribe, tags, conn.assigns[:locale]) do
          conn
          |> put_flash(:info, gettext("You has been subscribed successfully."))
          |> to_render(landing, Engagement.new_subscription())
        else
          conn
          |> put_flash(:error, gettext("An error happened trying to subscribe. Try again later."))
          |> to_render(landing, Engagement.new_subscription())
        end

      {:error, changeset} ->
        conn
        |> put_flash(
          :error,
          gettext("An error happened trying to subscribe. Maybe invalid name or email?")
        )
        |> to_render(landing, changeset)
    end
  end

  defp to_render(conn, %_{book: book} = landing, subscribe) when book != nil do
    Gettext.put_locale(BooksWeb.Gettext, book.lang)
    format_digital = Enum.find(book.formats, &(&1.name != :paper))
    format_paper = Enum.find(book.formats, &(&1.name == :paper))
    presale? = Catalog.book_in_presale?(book)
    released? = Catalog.book_released?(book)

    authors =
      book.roles
      |> Enum.filter(&(&1.role == :author))
      |> Enum.map(& &1.author)

    other_books =
      authors
      |> Enum.flat_map(fn author ->
        Catalog.books_by_author(author.id)
        |> Enum.reject(&(&1.id == book.id or &1.lang != book.lang))
      end)
      |> Enum.uniq_by(& &1.id)

    render(conn, "show_book.html",
      locale: book.lang,
      landing: landing,
      presale?: presale?,
      released?: released?,
      coming_soon?: not presale? and not released?,
      format_digital: format_digital,
      format_paper: format_paper,
      ##  FIXME: get real-country here? At the moment we have fixed prices so, not needed.
      shipping_cost: Books.Shipping.get_amount(nil),
      authors: authors,
      other_books: other_books,
      subscribe: subscribe
    )
  end

  defp to_render(conn, %{bundle: bundle} = landing, subscribe) when bundle != nil do
    Gettext.put_locale(BooksWeb.Gettext, bundle.lang)

    authors =
      bundle.formats
      |> Enum.flat_map(& &1.book.roles)
      |> Enum.filter(&(&1.role == :author))
      |> Enum.map(& &1.author)
      |> Enum.uniq_by(& &1.id)

    reviews = Enum.flat_map(bundle.formats, & &1.book.reviews)

    render(conn, "show_bundle.html",
      locale: bundle.lang,
      landing: landing,
      reviews: reviews,
      ##  FIXME: get real-country here? At the moment we have fixed prices so, not needed.
      shipping_cost: Books.Shipping.get_amount(nil),
      authors: authors,
      subscribe: subscribe
    )
  end
end
