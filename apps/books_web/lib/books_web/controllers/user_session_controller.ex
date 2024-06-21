defmodule BooksWeb.UserSessionController do
  use BooksWeb, :controller

  alias Books.Accounts
  alias BooksWeb.UserAuth

  def new(conn, params) do
    if redirect_to = params["redirect_to"] do
      conn
      |> put_session(:user_return_to, redirect_to)
      |> render(:new)
    else
      render(conn, :new)
    end
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, gettext("Invalid email or password"))
      |> render("new.html")
    end
  end

  def logout(conn, params), do: delete(conn, params)

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out successfully."))
    |> UserAuth.log_out_user()
  end
end
