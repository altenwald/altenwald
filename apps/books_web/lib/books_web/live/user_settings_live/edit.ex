defmodule BooksWeb.UserSettingsLive.Edit do
  use BooksWeb, :live_view
  require Logger
  alias Books.Accounts
  alias BooksWeb.UserSettingsLive.{ChangePassword, Interest, Marketing}

  def fetch_live_current_user(socket, session) do
    user_token = session["user_token"]
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(socket, :current_user, user)
  end

  def fetch_locale(socket, session) do
    locale = session["locale"]
    Gettext.put_locale(BooksWeb.Gettext, locale)
    assign(socket, :locale, locale)
  end

  defp assign_email_and_password_changesets(conn) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> fetch_live_current_user(session)
      |> fetch_locale(session)
      |> assign_email_and_password_changesets()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, action, params) do
    Logger.info("action=#{inspect(action)} params=#{inspect(params)}")
    socket
  end

  @impl true
  def handle_event(event, params, socket) do
    Logger.warning("unexpected: #{inspect(event)} #{inspect(params)}")
    {:noreply, socket}
  end
end
