defmodule BooksWeb.ErrorHTMLTest do
  use BooksWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(BooksWeb.ErrorHTML, "404", "html", []) =~ "página no encontrada"
  end

  test "renders 500.html" do
    assert render_to_string(BooksWeb.ErrorHTML, "500", "html", []) =~ "Error de Servidor"
  end
end
