defmodule BooksWeb.LocaleController do
  use BooksWeb, :controller
  require Logger

  def set_lang_en(conn, params) do
    set_lang(conn, Map.put(params, "lang", "en"))
  end

  def set_lang_es(conn, params) do
    set_lang(conn, Map.put(params, "lang", "es"))
  end

  def set_lang(conn, %{"lang" => locale, "redirect" => redirect}) do
    Gettext.put_locale(BooksWeb.Gettext, locale)
    Logger.debug("setting locale as '#{locale}'")

    conn
    |> put_session(:locale, locale)
    |> put_status(:temporary_redirect)
    |> assign(:locale, locale)
    |> redirect(to: Path.join(["/", redirect]))
  end
end
