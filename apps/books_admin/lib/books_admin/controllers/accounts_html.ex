defmodule BooksAdmin.AccountsHTML do
  use BooksAdmin, :html
  import BooksAdmin.PaginationComponent

  embed_templates("accounts_html/*")
end
