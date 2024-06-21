defmodule BooksAdmin.ReviewsController do
  use BooksAdmin, :controller
  require Logger
  alias Books.Catalog

  defp default_return_to(conn, book_slug) do
    Routes.catalog_reviews_path(conn, :index, book_slug)
  end

  def edit(conn, %{"catalog_id" => book_slug, "id" => id} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    review = Catalog.get_review(id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)
    render(conn, "edit.html", options(book, review, Catalog.change_review(review), return_to))
  end

  def new(conn, %{"catalog_id" => book_slug} = params) do
    book = Catalog.get_book_by_slug(book_slug)
    review = Catalog.new_review(book.id)
    return_to = params["return_to"] || default_return_to(conn, book_slug)
    render(conn, "new.html", options(book, review, Catalog.change_review(review), return_to))
  end

  def update(
        conn,
        %{"catalog_id" => book_slug, "id" => review_id, "review" => params} = global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         params = Map.put(params, "book_id", book.id),
         review when review != nil <- Catalog.get_review(review_id) do
      changeset = Catalog.change_review(review, params)

      case Books.Repo.update(changeset) do
        {:ok, _review} ->
          conn
          |> put_flash(:info, gettext("Review modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(book, review, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Review not found"))
        |> redirect(to: return_to)
    end
  end

  def create(conn, %{"catalog_id" => book_slug, "review" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn, book_slug)

    if book = Catalog.get_book_by_slug(book_slug) do
      review = Catalog.new_review(book.id)
      params = Map.put(params, "book_id", book.id)
      changeset = Catalog.change_review(review, params)

      case Books.Repo.insert(changeset) do
        {:ok, _review} ->
          conn
          |> put_flash(:info, gettext("Review created successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("new.html", options(book, review, changeset, return_to))
      end
    else
      conn
      |> put_flash(:error, gettext("Review not found"))
      |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"catalog_id" => book_slug, "id" => review_id} = params) do
    return_to = params["return_to"] || default_return_to(conn, book_slug)

    with book when book != nil <- Catalog.get_book_by_slug(book_slug),
         review when review != nil <- Catalog.get_review(review_id) do
      case Books.Repo.delete(review) do
        {:ok, _review} ->
          conn
          |> put_flash(:info, gettext("Review removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{review_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove review"))
          |> redirect(to: return_to)
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Review not found"))
        |> redirect(to: return_to)
    end
  end

  defp options(book, review, changeset, return_to) do
    [
      title:
        case review do
          %_{id: nil} ->
            gettext("New review from %{slug}", slug: book.slug)

          _ ->
            gettext("Review %{author} from %{slug}",
              author: review.full_name,
              slug: book.slug
            )
        end,
      book: book,
      changeset: changeset,
      review: review,
      return_to: return_to
    ]
  end
end
