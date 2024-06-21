defmodule BooksWeb.UserSettingsLive.Marketing do
  use BooksWeb, :live_component

  require Logger

  @impl true
  def update(assigns, socket) do
    user = assigns.current_user

    socket =
      socket
      |> assign(:marketing_options, marketing_options(user.email))
      |> assign(:current_user, user)
      |> assign(:locale, assigns.locale)
      |> assign(:status_id, nil)

    {:ok, socket}
  end

  defp marketing_options(email) do
    case Mailchimp.get_member_permissions(email) do
      {:ok, permissions} ->
        permissions

      error ->
        Logger.error("marketing options: #{inspect(error)}")
        nil
    end
  end

  @impl true
  def handle_event("change", %{"id" => id} = params, socket) do
    user = socket.assigns.current_user
    enabled? = !!params["value"]
    Logger.info("update permission for #{user.email} #{inspect(id)} to #{enabled?}")
    socket = assign(socket, :status_id, id)

    case Mailchimp.update_member_permission(user.email, id, enabled?) do
      {:ok, _} ->
        socket =
          socket
          |> assign(:marketing_options, marketing_options(user.email))
          |> assign(:status_ok, true)

        {:noreply, socket}

      {:error, reason} ->
        Logger.error(
          "update permission for #{user.email} #{inspect(id)} to #{enabled?}: #{inspect(reason)}"
        )

        {:noreply, assign(socket, :status_ok, false)}
    end
  end

  defp help_for("a670112873") do
    gettext("""
    Recibe publicidad personalizada. Esta publicidad estará basada en sus intereses.
    Vea más abajo la configuración de Intereses.
    """)
  end

  defp help_for("ee60c80222") do
    gettext("""
    Permite a nuestro equipo poder enviarle mensajes directos para alguna consulta
    puntual o encuesta.
    """)
  end

  defp help_for("7400189b73") do
    gettext("""
    Permite a nuestro sistema enviarle mensajes con respecto a actualizaciones de sus
    productos comprados, compra de productos, recibos y otra información importante.
    """)
  end

  defp translate("7400189b73", _default), do: gettext("Correo electrónico")
  defp translate("ee60c80222", _default), do: gettext("Correo directo")
  defp translate("a670112873", _default), do: gettext("Publicidad en línea personalizada")

  defp translate(id, default) do
    Logger.warning("cannot find translation for: #{inspect(id)}")
    default
  end
end
