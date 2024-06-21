defmodule BooksWeb.UserConfirmationController do
  use BooksWeb, :controller

  alias Books.Accounts

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(conn, :edit, &1),
        conn.assigns[:locale]
      )
    end

    conn
    |> put_flash(
      :info,
      gettext("""
      If your email is in our system and it has not been confirmed yet,
      you will receive an email with instructions shortly.
      """)
    )
    |> redirect(to: Routes.catalog_path(conn, :index))
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def update(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, user} ->
        {:ok, encoded_token, _user_token} = Accounts.create_user_reset_password_token(user)

        conn
        |> put_flash(
          :info,
          gettext("User confirmed successfully. You need to configure a password.")
        )
        |> redirect(to: Routes.user_reset_password_path(conn, :edit, encoded_token))

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: Routes.catalog_path(conn, :index))

          %{} ->
            conn
            |> put_flash(:error, gettext("User confirmation link is invalid or it has expired."))
            |> redirect(to: Routes.catalog_path(conn, :index))
        end
    end
  end
end
