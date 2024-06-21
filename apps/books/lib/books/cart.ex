defmodule Books.Cart do
  import Ecto.Query, only: [from: 2]
  alias Books.Cart.{Order, Worker}
  alias Books.Repo

  @registry Books.Cart.Registry
  @supervisor Books.Cart

  @pubsub Books.PubSub
  @topic "cart"

  def registry_name, do: @registry
  def supervisor_name, do: @supervisor

  def via(id), do: {:via, Registry, {@registry, id}}

  def start(nil, _remote_ip, _email), do: {:error, :invalid_id}

  def start(id, remote_ip, email) do
    DynamicSupervisor.start_child(@supervisor, {Worker, [id, remote_ip, email]})
  end

  def get_active_orders do
    DynamicSupervisor.which_children(@supervisor)
    |> Stream.map(fn {:undefined, pid, :worker, [Worker]} -> pid end)
    |> Stream.map(&hd(Registry.keys(@registry, &1)))
    |> Enum.map(&get_order(&1))
  end

  def list_orders do
    stored_orders =
      from(
        o in Order,
        preload: ^Order.preload_relations()
      )
      |> Repo.all()
      |> Stream.map(&Order.update_virtual_items/1)
      |> Enum.map(&Order.update_virtual/1)

    (get_active_orders() ++ stored_orders)
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> Enum.uniq_by(& &1.id)
  end

  @default_page_size 10

  def list_orders_paginated(params) do
    params = Map.merge(%{"page_size" => @default_page_size}, params)

    stored_orders =
      from(
        o in Order,
        preload: ^Order.preload_relations()
      )
      |> Repo.all()
      |> Stream.map(&Order.update_virtual_items/1)
      |> Enum.map(&Order.update_virtual/1)

    (get_active_orders() ++ stored_orders)
    |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
    |> Enum.uniq_by(& &1.id)
    |> Scrivener.paginate(params)
  end

  def list_paid_orders_by_email(email) do
    from(
      o in Order,
      where: o.state == :paid and o.email == ^email,
      preload: ^Order.preload_relations(),
      order_by: [desc: o.inserted_at]
    )
    |> Repo.all()
    |> Stream.map(&Order.update_virtual_items/1)
    |> Enum.map(&Order.update_virtual/1)
  end

  def running?(nil), do: false
  def running?(id), do: Registry.lookup(@registry, id) != []

  defdelegate start_link(opts), to: Worker

  defdelegate stop(id), to: Worker

  def ensure_stopped(id) do
    if running?(id), do: stop(id)
  end

  def get_by_payment_id(payment_id) do
    case Registry.meta(@registry, {:payment_id, payment_id}) do
      {:ok, id} -> id
      :error -> nil
    end
  end

  def get_by_token(token) do
    case Registry.meta(@registry, {:token, token}) do
      {:ok, id} -> id
      :error -> nil
    end
  end

  defp call(id, data) do
    if running?(id), do: GenStateMachine.call(via(id), data)
  end

  defp cast(id, data) do
    if running?(id), do: GenStateMachine.cast(via(id), data)
  end

  def ensure_get_order(nil), do: nil

  def ensure_get_order(id) do
    get_order(id) || get_stored_order(id)
  end

  def list_orders_by_date(start_date) do
    query =
      from o in Order,
        where: o.inserted_at >= ^start_date,
        order_by: o.inserted_at,
        preload: ^Order.preload_relations()

    for order <- Repo.all(query) do
      order
      |> Order.update_virtual_items()
      |> Order.update_virtual()
    end
  end

  def list_orders_by_email(email) do
    query =
      from o in Order,
        where: o.email == ^email,
        order_by: [desc: o.inserted_at],
        preload: ^Order.preload_relations()

    for order <- Repo.all(query) do
      order
      |> Order.update_virtual_items()
      |> Order.update_virtual()
    end
  end

  def get_stored_order(id) do
    query =
      from o in Order,
        where: o.id == ^id,
        preload: ^Order.preload_relations()

    Repo.one(query)
    |> Order.update_virtual_items()
    |> Order.update_virtual()
  end

  def change_order(order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def change_shipping(order_id, attrs) do
    ensure_stopped(order_id)

    if order = get_stored_order(order_id) do
      attrs = Map.take(attrs, ~w[ shipping_status shipping_status_at shipping_tracking_url ])
      changeset = Order.changeset(order, attrs)
      Repo.update(changeset)
    else
      {:error, :notfound}
    end
  end

  def get_order(id), do: call(id, :get_order)
  def get_files(id), do: call(id, :files)
  def get_payment_id(id), do: call(id, :payment_id)
  def get_payment_option(id), do: call(id, :payment_option)
  def get_num_items(id), do: call(id, :num_items)

  def add_offer(id, offer), do: cast(id, {:add_offer, offer})
  def check_offers(id), do: cast(id, :check_offers)
  def add_item(id, format_id), do: cast(id, {:add_item, format_id})
  def rem_item(id, format_id), do: cast(id, {:rem_item, format_id})
  def set_payment_id(id, payment_id), do: cast(id, {:set_payment_id, payment_id})
  def set_token(id, token), do: cast(id, {:set_token, token})

  def process(id, params), do: call(id, {:process, params})
  def pay(id, info, locale), do: cast(id, {:pay, info, locale})
  def cancel(id), do: cast(id, :cancel)
  def save(id), do: cast(id, :save)

  def shipping?(id), do: call(id, :shipping?)
  def digital?(id), do: call(id, :digital?)
  def presale?(id), do: call(id, :presale?)
  def expired?(id), do: call(id, :expired?)

  defp lang_tag("en"), do: ["english"]
  defp lang_tag("es"), do: ["spanish"]
  defp lang_tag(_ohter), do: []

  def get_tags_by_book(book) do
    ["#{book.slug}-#{book.edition}ed" | lang_tag(book.lang)]
  end

  def subscribe do
    true = Process.alive?(Process.whereis(@pubsub))
    :ok = Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  def notify(event) do
    Phoenix.PubSub.broadcast(@pubsub, @topic, event)
    event
  end
end
