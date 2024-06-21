defmodule BooksWeb.LegalController do
  use BooksWeb, :controller

  plug :put_layout, html: {BooksWeb.Layouts, :legal}

  def privacy_en(conn, _params) do
    if conn.assigns[:locale] == "es" do
      redirect(conn, to: Routes.legal_path(conn, :privacy_es))
    else
      render(conn, "privacy_en.html", default_opts(conn, title: gettext("Privacy Policy")))
    end
  end

  def privacy_es(conn, _params) do
    if conn.assigns[:locale] == "en" do
      redirect(conn, to: Routes.legal_path(conn, :privacy_en))
    else
      render(conn, "privacy_es.html", default_opts(conn, title: gettext("Privacy Policy")))
    end
  end

  def cookies_en(conn, _params) do
    if conn.assigns[:locale] == "es" do
      redirect(conn, to: Routes.legal_path(conn, :cookies_es))
    else
      render(conn, "cookies_en.html", default_opts(conn, title: gettext("Cookies Policy")))
    end
  end

  def cookies_es(conn, _params) do
    if conn.assigns[:locale] == "en" do
      redirect(conn, to: Routes.legal_path(conn, :cookies_en))
    else
      render(conn, "cookies_es.html", default_opts(conn, title: gettext("Cookies Policy")))
    end
  end

  def tos_en(conn, _params) do
    if conn.assigns[:locale] == "es" do
      redirect(conn, to: Routes.legal_path(conn, :tos_es))
    else
      render(conn, "tos_en.html", default_opts(conn, title: gettext("Terms of Service")))
    end
  end

  def tos_es(conn, _params) do
    if conn.assigns[:locale] == "en" do
      redirect(conn, to: Routes.legal_path(conn, :tos_en))
    else
      render(conn, "tos_es.html", default_opts(conn, title: gettext("Terms of Service")))
    end
  end

  def about_en(conn, _params) do
    if conn.assigns[:locale] == "es" do
      redirect(conn, to: Routes.legal_path(conn, :about_es))
    else
      render(conn, "about_en.html", default_opts(conn, title: gettext("About")))
    end
  end

  def about_es(conn, _params) do
    if conn.assigns[:locale] == "en" do
      redirect(conn, to: Routes.legal_path(conn, :about_en))
    else
      render(conn, "about_es.html", default_opts(conn, title: gettext("About")))
    end
  end
end
