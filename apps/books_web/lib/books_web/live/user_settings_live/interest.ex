defmodule BooksWeb.UserSettingsLive.Interest do
  use BooksWeb, :live_component

  require Logger

  alias Books.Engagement

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:interests, Engagement.get_category_tags())
      |> assign(:current_user, assigns.current_user)
      |> assign(:locale, assigns.locale)
      |> assign(:status_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("change", params, socket) do
    enable? = !!params["value"]
    user = socket.assigns.current_user

    socket.assigns[:interests]
    |> Enum.find(fn {category, _tags} -> category.id == params["id"] end)
    |> case do
      nil ->
        {:noreply, socket}

      {category, tags} ->
        if enable? do
          Engagement.user_subscribe_tags(user, tags)
        else
          Engagement.user_unsubscribe_tags(user, tags)
        end
        |> case do
          {:ok, user} ->
            socket =
              socket
              |> assign(:current_user, user)
              |> assign(:status_id, category.id)
              |> assign(:status_ok, true)

            {:noreply, socket}

          {:error, reason} ->
            Logger.error("update intereset for #{user.email}: #{inspect(reason)}")

            socket =
              socket
              |> assign(:status_id, category.id)
              |> assign(:status_ok, false)

            {:noreply, socket}
        end
    end
  end

  def checked?(user, tags) do
    tags = MapSet.new(tags)
    user_tags = MapSet.new(user.mailling_tags)
    MapSet.subset?(tags, user_tags)
  end
end
