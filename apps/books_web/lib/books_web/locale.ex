defmodule BooksWeb.Locale do
  import Plug.Conn
  require Logger

  @langs ~w[en es]

  def init(_opts), do: nil

  def call(%_{path_info: [locale | uri]} = conn, opts) when locale in @langs do
    Logger.debug("setting locale as '#{locale}")

    conn
    |> put_session(:locale, locale)
    |> assign(:locale, locale)
    |> Plug.forward(uri, BooksWeb.Router, opts)
    |> halt()
  end

  def call(conn, _opts) do
    case conn.params["locale"] || get_session(conn, :locale) || get_lang() do
      nil ->
        Logger.error("ignoring locale!!!")
        conn

      locale ->
        Gettext.put_locale(BooksWeb.Gettext, locale)
        Logger.debug("setting locale as '#{locale}'")

        conn
        |> put_session(:locale, locale)
        |> assign(:locale, locale)
    end
  end

  def get_lang, do: Gettext.get_locale()
end
