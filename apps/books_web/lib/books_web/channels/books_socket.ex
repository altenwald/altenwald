defmodule BooksWeb.BooksSocket do
  use Phoenix.Socket
  require Logger

  ## Channels
  channel "books:admin:cart", BooksAdmin.CartChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token}, socket, connect_info) do
    socket =
      socket
      |> assign(:token, token)
      |> assign(:remote_ip, remote_ip(connect_info))

    {:ok, socket}
  end

  defp remote_ip(%{x_headers: [], peer_data: %{address: ip}}) do
    to_string(:inet_parse.ntoa(ip))
  end

  defp remote_ip(%{x_headers: x_headers, peer_data: %{address: peer_ip}}) do
    case RemoteIp.from(x_headers) do
      ip when is_tuple(ip) -> to_string(:inet_parse.ntoa(ip))
      nil -> to_string(:inet_parse.ntoa(peer_ip))
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     BooksWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
