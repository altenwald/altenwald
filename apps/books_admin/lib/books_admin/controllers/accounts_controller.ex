defmodule BooksAdmin.AccountsController do
  use BooksAdmin, :controller
  alias Books.Accounts

  def index(conn, params) do
    render(conn, "index.html",
      title: gettext("Accounts"),
      page: Accounts.list_users_paginated(params)
    )
  end
end
