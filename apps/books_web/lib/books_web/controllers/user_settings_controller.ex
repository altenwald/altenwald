defmodule BooksWeb.UserSettingsController do
  use BooksWeb, :controller

  require Logger

  alias Books.{Accounts, Catalog, Engagement}

  plug :assign_email_and_password_changesets
  plug :book_slug when action in [:subscribe, :unsubscribe]

  defp book_slug(conn, _params) do
    Logger.debug("conn => #{inspect(conn)}")

    if book_slug = conn.params["book_slug"] do
      if book = Catalog.get_book_by_slug(book_slug) do
        assign(conn, :book, book)
      else
        raise BooksWeb.ErrorNotFound, message: gettext("book not found")
      end
    else
      conn
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, gettext("Email changed successfully."))
        |> redirect(to: Routes.user_settings_edit_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, gettext("Email change link is invalid or it has expired."))
        |> redirect(to: Routes.user_settings_edit_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end

  defp redirect_to(conn, params) do
    with nil <- params["return-to"],
         [] <- get_req_header(conn, "referer") do
      Routes.catalog_path(conn, :index)
    else
      [url] -> URI.new!(url).path
      path when is_binary(path) -> path
    end
  end

  def subscribe(conn, %{"book_slug" => _slug} = params) do
    user = conn.assigns.current_user
    book = conn.assigns.book
    Engagement.user_subscribe_book(user, book)

    conn
    |> put_flash(:info, gettext("You has been subscribed successfully."))
    |> redirect(to: redirect_to(conn, params))
  end

  def unsubscribe(conn, %{"book_slug" => _slug} = params) do
    user = conn.assigns.current_user
    book = conn.assigns.book
    Engagement.user_unsubscribe_book(user, book)

    conn
    |> put_flash(:info, gettext("You has been unsubscribed successfully."))
    |> redirect(to: redirect_to(conn, params))
  end
end
