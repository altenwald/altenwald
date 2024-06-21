defmodule BooksWeb.ErrorNotFound do
  defexception message: "invalid route", plug_status: 404
end
