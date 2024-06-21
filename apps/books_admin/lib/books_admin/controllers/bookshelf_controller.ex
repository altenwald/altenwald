defmodule BooksAdmin.BookshelfController do
  use BooksAdmin, :controller
  require Logger
  alias Books.{Accounts, Cart, Catalog}

  def index(conn, %{"accounts_id" => accounts_id}) do
    account = Accounts.get_user(accounts_id)

    render(conn, "index.html",
      title: gettext("Bookshelf for %{name}", name: account.email),
      bookshelf_items: Accounts.get_bookshelf_by_user(account),
      account: account
    )
  end

  defp default_return_to(conn, user_id) do
    Routes.accounts_bookshelf_path(conn, :index, user_id)
  end

  def edit(conn, %{"accounts_id" => accounts_id, "id" => id} = params) do
    account = Accounts.get_user(accounts_id)
    bookshelf_item = Accounts.get_bookshelf(id)
    return_to = params["return_to"] || default_return_to(conn, accounts_id)

    render(
      conn,
      "edit.html",
      options(account, bookshelf_item, Accounts.change_bookshelf_item(bookshelf_item), return_to)
    )
  end

  def new(conn, %{"accounts_id" => accounts_id} = params) do
    account = Accounts.get_user(accounts_id)
    bookshelf_item = Accounts.new_bookshelf_item(accounts_id)
    return_to = params["return_to"] || default_return_to(conn, accounts_id)

    render(
      conn,
      "new.html",
      options(account, bookshelf_item, Accounts.change_bookshelf_item(bookshelf_item), return_to)
    )
  end

  def update(
        conn,
        %{"accounts_id" => accounts_id, "id" => id, "bookshelf_item" => params} = global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn, accounts_id)

    with account when account != nil <- Accounts.get_user(accounts_id),
         params = Map.put(params, "user_id", account.id),
         bookshelf_item when bookshelf_item != nil <- Accounts.get_bookshelf(id) do
      changeset = Accounts.change_bookshelf_item(bookshelf_item, params)

      case Books.Repo.update(changeset) do
        {:ok, _bookshelf_item} ->
          conn
          |> put_flash(:info, gettext("Bookshelf item modified successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("edit.html", options(account, bookshelf_item, changeset, return_to))
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Bookshelf item not found"))
        |> redirect(to: return_to)
    end
  end

  def create(conn, %{"accounts_id" => accounts_id, "bookshelf_item" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn, accounts_id)

    if account = Accounts.get_user(accounts_id) do
      bookshelf_item = Accounts.new_bookshelf_item(accounts_id)
      params = Map.put(params, "user_id", account.id)
      changeset = Accounts.change_bookshelf_item(bookshelf_item, params)

      case Books.Repo.insert(changeset) do
        {:ok, _bookshelf_item} ->
          conn
          |> put_flash(:info, gettext("Bookshelf item created successfully!"))
          |> redirect(to: return_to)

        {:error, changeset} ->
          conn
          |> put_flash(:error, gettext("Found validation errors, see below"))
          |> render("new.html", options(account, bookshelf_item, changeset, return_to))
      end
    else
      conn
      |> put_flash(:error, gettext("Bookshelf item not found"))
      |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"accounts_id" => accounts_id, "id" => bookshelf_item_id} = params) do
    return_to = params["return_to"] || default_return_to(conn, accounts_id)

    with account when account != nil <- Accounts.get_user(accounts_id),
         bookshelf_item when bookshelf_item != nil <- Accounts.get_bookshelf(bookshelf_item_id) do
      case Books.Repo.delete(bookshelf_item) do
        {:ok, _bookshelf_item} ->
          conn
          |> put_flash(:info, gettext("Bookshelf item removed successfully!"))
          |> redirect(to: return_to)

        {:error, reason} ->
          Logger.error("cannot remove #{bookshelf_item_id}, reason: #{inspect(reason)}")

          conn
          |> put_flash(:error, gettext("Cannot remove bookshelf item"))
          |> redirect(to: return_to)
      end
    else
      nil ->
        conn
        |> put_flash(:error, gettext("Bookshelf item not found"))
        |> redirect(to: return_to)
    end
  end

  defp options(account, bookshelf_item, changeset, return_to) do
    [
      title:
        case bookshelf_item do
          %_{id: nil} ->
            gettext("New bookshelf item for %{name}", name: account.email)

          _ ->
            gettext("Bookshelf item for %{name}", name: account.email)
        end,
      account: account,
      changeset: changeset,
      bookshelf_item: bookshelf_item,
      item_types: list_item_types(),
      books: list_books(),
      orders: list_orders(account.email),
      return_to: return_to
    ]
  end

  defp list_orders(email) do
    for order <- Cart.list_paid_orders_by_email(email) do
      {"#{NaiveDateTime.to_date(order.inserted_at)} -- #{order.total_price}", order.id}
    end
  end

  defp list_books do
    for book <- Catalog.list_all_books_simple() do
      {Catalog.get_full_book_title(book), book.id}
    end
  end

  defp list_item_types do
    [
      {gettext("Purchased"), "purchased"},
      {gettext("External"), "external"},
      {gettext("Author"), "author"}
    ]
  end
end
