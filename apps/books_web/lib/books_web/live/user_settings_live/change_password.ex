defmodule BooksWeb.UserSettingsLive.ChangePassword do
  use BooksWeb, :live_component

  require Logger

  alias Books.Accounts

  @impl true
  def update(assigns, socket) do
    user = assigns.current_user

    socket =
      socket
      |> assign(:password_changeset, Accounts.change_user_password(user))
      |> assign(:current_user, user)
      |> assign(:locale, assigns.locale)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"current_password" => _current_password, "user" => params},
        socket
      ) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_password(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"current_password" => current_password, "user" => params}, socket) do
    user = socket.assigns.current_user

    socket =
      case Accounts.update_user_password(user, current_password, params) do
        {:ok, _user} ->
          socket
          |> put_flash(:info, gettext("Password updated successfully."))
          |> redirect(to: Routes.user_session_path(socket, :delete))

        {:error, changeset} ->
          socket
          |> put_flash(:error, gettext("Something went wrong, review the form"))
          |> assign(:password_changeset, changeset)
          |> tap(fn socket ->
            Logger.warning("errors? #{inspect(socket.assigns.password_changeset.errors)}")
          end)
      end

    {:noreply, socket}
  end
end
