defmodule BooksWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BooksWeb.ChannelCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint BooksWeb.Endpoint

      use BooksWeb, :verified_routes

      # Import conveniences for testing with channels
      import Plug.Conn
      import Phoenix.ChannelTest
      import BooksWeb.ChannelCase
    end
  end

  setup tags do
    Books.DataCase.setup_sandbox(tags)
    :ok
  end
end
