defmodule BooksAdmin.Endpoint do
  use Phoenix.Endpoint, otp_app: :books_admin

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :ets,
    table: :session,
    key: "_books_key",
    max_age: 3_600 * 6
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  socket("/socket", BooksAdmin.BooksSocket,
    websocket: [connect_info: [:peer_data, :x_headers]],
    longpoll: [connect_info: [:peer_data, :x_headers]]
  )

  plug(Plug.RequestId)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(BooksAdmin.Router)
end
