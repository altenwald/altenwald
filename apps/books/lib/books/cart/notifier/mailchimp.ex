defmodule Books.Cart.Notifier.Mailchimp do
  use GenServer
  require Logger

  alias Books.Cart

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    Cart.subscribe()
    {:ok, nil}
  end

  @impl GenServer
  def handle_info(event, state) do
    process_event(event, state)
    {:noreply, state}
  end

  defp process_event({:paid, order_id, _remote_ip, _locale}, _state) do
    order = Cart.ensure_get_order(order_id)

    for item <- order.items do
      book = item.format.book
      tags = Cart.get_tags_by_book(book)

      data = %{
        "email_address" => order.email,
        "status" => "subscribed",
        "language" => book.lang,
        "tags" => tags,
        "merge_fields" => %{
          "FNAME" => order.first_name,
          "LNAME" => order.last_name
        }
      }

      Logger.info("add member #{order.email} to mailling list")

      case Mailchimp.add_member(data) do
        {:ok, %{"status" => 400, "title" => "Member Exists"}} ->
          Logger.warning("user #{order.email} was already registerd in mailchimp")
          res = Mailchimp.add_tags(order.email, tags)
          Logger.debug("add tags output => #{inspect(res)}")
          true

        {:ok, %{"status" => "subscribed"}} ->
          true

        {:ok, %{"status" => status, "title" => msg}} ->
          Logger.error("status=#{status} msg=#{msg}")
          false

        {:error, error} ->
          Logger.error("cannot add email #{order.email} => #{inspect(error)}")
          false
      end
    end
    |> Enum.all?()
  end

  defp process_event(_event, _state), do: :ok
end
