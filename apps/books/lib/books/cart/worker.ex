defmodule Books.Cart.Worker do
  use GenStateMachine, callback_mode: :state_functions, restart: :temporary
  require Logger

  alias Books.Ads.Offer
  alias Books.{Cart, Repo}
  alias Books.Cart.Order
  alias Books.Cart.OrderItem
  alias Ecto.Changeset

  ## TODO: move these timer config data to configuration.

  # Time to drop new orders (1 hora = 3,600,000 ms)
  @time_drop_new 3_600_000

  # Time to stop orders (which are in states like 'paid' or 'cancelled')
  # (1 hour = 3,600,000 ms)
  @time_to_stop 3_600_000

  # Time to drop waiting orders (6 hours = 21,600,000 ms)
  @time_drop_waiting 21_600_000

  # Possible fields to ask to
  @request_fields ~w[
    digital?
    shipping?
    presale?
    payment_id
    payment_option
  ]a

  # For tests, development and when the country API is failing, just in case:
  @default_country "ES"

  def start_link([id, remote_ip, email]) do
    name = Cart.via(id)
    GenStateMachine.start_link(__MODULE__, [id, remote_ip, email], name: name)
  end

  def stop(id), do: GenStateMachine.stop(Cart.via(id))

  @impl GenStateMachine
  def init([id, remote_ip, email]) do
    changeset =
      case Cart.get_stored_order(id) do
        nil ->
          inserted_at =
            NaiveDateTime.utc_now()
            |> NaiveDateTime.truncate(:second)

          Order.changeset(%{})
          |> Changeset.put_change(:id, id)
          |> Changeset.put_change(:remote_ip, remote_ip)
          |> Changeset.put_change(:email, email)
          |> Changeset.put_change(:country, get_remote_country(remote_ip))
          |> Changeset.put_change(:inserted_at, inserted_at)
          |> Order.set_action(:insert)

        order ->
          order
          |> Order.changeset(%{})
          |> maybe_set_remote_ip(remote_ip)
          |> set_payment_id()
          |> set_token()
          |> Order.set_action(:update)
      end

    state_name = get_state_name(changeset)
    notify(changeset, {:init, state_name})
    {:ok, state_name, changeset, timeout(state_name)}
  end

  @impl GenStateMachine
  def code_change(_old_vsn, state, data, _extra) do
    {:ok, state, data}
  end

  defp maybe_set_remote_ip(changeset, remote_ip) do
    old_remote_ip = Changeset.get_field(changeset, :remote_ip)

    if remote_ip != old_remote_ip do
      changeset
      |> Changeset.put_change(:remote_ip, remote_ip)
      |> Changeset.put_change(:country, get_remote_country(remote_ip))
    else
      changeset
    end
  end

  defp get_remote_country(remote_ip) do
    case Geoip.geoip(remote_ip) do
      nil -> @default_country
      country -> country
    end
  end

  ## State: NEW
  ## In this state is possible modify the order, add items, add offers,
  ## and add information for payment.

  def new(:timeout, :drop, changeset) do
    notify(changeset, :drop)
    {:next_state, :cancelled, changeset, timeout(:cancelled)}
  end

  def new(:cast, :cancel, changeset) do
    notify(changeset, :cancelled)
    {:next_state, :cancelled, changeset, timeout(:cancelled)}
  end

  def new(:cast, {:add_offer, offer}, changeset) do
    {combo, no_combo} =
      changeset
      |> Changeset.get_field(:offers)
      |> Enum.split_with(&(&1.type == :combo))

    Logger.debug("combo offers => #{inspect(Enum.map(combo, & &1.name))}")
    Logger.debug("no combo offers => #{inspect(Enum.map(no_combo, & &1.name))}")

    no_combo =
      [offer | no_combo]
      |> Enum.sort_by(& &1.discount_amount, &>=/2)
      |> hd()

    offers = [no_combo | combo]
    notify(changeset, {:add_offer, offer, offers})
    Logger.debug("offer => #{inspect(offer.name)}")
    Logger.debug("offers => #{inspect(Enum.map(offers, & &1.name))}")

    changeset =
      changeset
      |> Changeset.put_assoc(:offers, offers)

    {:keep_state, changeset, timeout(:new)}
  end

  def new(:cast, :check_offers, changeset) do
    combo =
      changeset
      |> Changeset.get_field(:items)
      |> Enum.map(& &1.format_id)
      |> Offer.search_offer()

    no_combo =
      changeset
      |> Changeset.get_field(:offers)
      |> Enum.filter(&(&1.type != :combo))

    offers = no_combo ++ combo

    changeset = Changeset.put_assoc(changeset, :offers, offers)
    notify(changeset, {:check_offers, offers})
    {:keep_state, changeset, timeout(:new)}
  end

  def new(:cast, {:add_item, format_id}, changeset) do
    items = Changeset.get_field(changeset, :items)

    num_items =
      items
      |> Enum.map(& &1.quantity)
      |> Enum.sum()

    order = Changeset.apply_changes(changeset)

    if num_items < 20 do
      items = OrderItem.add(items, format_id, order)

      changeset = Changeset.put_assoc(changeset, :items, items)
      notify(changeset, {:add_item, format_id})
      actions = [{:next_event, :cast, :check_offers}, timeout(:new)]
      {:keep_state, changeset, actions}
    else
      Logger.warning("trying to add more than 20 items to the cart #{inspect(order)}")
      {:keep_state_and_data, timeout(:new)}
    end
  end

  def new(:cast, {:rem_item, format_id}, changeset) do
    order = Changeset.apply_changes(changeset)

    items =
      changeset
      |> Changeset.get_field(:items)
      |> OrderItem.rem(format_id, order)

    changeset = Changeset.put_assoc(changeset, :items, items)
    notify(changeset, {:rem_item, format_id})
    actions = [{:next_event, :cast, :check_offers}, timeout(:new)]
    {:keep_state, changeset, actions}
  end

  def new({:call, from}, field, changeset) when field in @request_fields do
    gen_reply(changeset, field, :new, from)
  end

  def new({:call, from}, :get_order, changeset) do
    reply_order(changeset, :new, from)
  end

  def new({:call, from}, :num_items, changeset) do
    num_items =
      changeset
      |> Changeset.get_field(:items)
      |> Enum.map(& &1.quantity)
      |> Enum.sum()

    gen_reply(num_items, :new, from)
  end

  def new({:call, from}, {:process, params}, changeset) do
    Logger.debug("params => #{inspect(params)}")
    changeset = Order.changeset(changeset, params)
    Logger.debug("changeset errors => #{inspect(changeset.errors)}")

    if changeset.valid? do
      changeset = Changeset.put_change(changeset, :state, :waiting)
      notify(changeset, {:process, :valid})
      Logger.debug("changeset => #{inspect(changeset)}")
      {:next_state, :waiting, changeset, [{:reply, from, true}]}
    else
      notify(changeset, {:process, :invalid})
      {:keep_state, changeset, {:reply, from, false}}
    end
  end

  ## State: WAITING
  ## In this state we are waiting for input from payment providers. We can
  ## move to PAID or CANCELLED states.

  def waiting(:cast, {:set_payment_id, payment_id}, changeset) do
    changeset =
      changeset
      |> Changeset.put_change(:payment_id, payment_id)
      |> set_payment_id()

    {:keep_state, changeset, timeout(:waiting)}
  end

  def waiting(:cast, {:set_token, token}, changeset) do
    changeset =
      changeset
      |> Changeset.put_change(:token, token)
      |> set_token()

    {:keep_state, changeset, timeout(:waiting)}
  end

  def waiting(:cast, {:pay, info, locale}, changeset) do
    payer_info = info["payer"]["payer_info"]

    changeset =
      changeset
      |> Changeset.put_change(:payer_email, payer_info["email"])
      |> Changeset.put_change(:payer_first_name, payer_info["first_name"])
      |> Changeset.put_change(:payer_last_name, payer_info["last_name"])
      |> Changeset.put_change(:state, :paid)
      |> store()

    notify(changeset, {:paid, locale})
    {:next_state, :paid, changeset, timeout(:paid)}
  end

  def waiting(:cast, :cancel, changeset) do
    changeset =
      changeset
      |> Changeset.put_change(:state, :cancelled)
      |> store()

    notify(changeset, :cancelled)
    {:next_state, :cancelled, changeset, timeout(:cancelled)}
  end

  def waiting(:cast, :save, changeset) do
    changeset = store(changeset)
    notify(changeset, :processing)
    {:keep_state, changeset, timeout(:waiting)}
  end

  def waiting(:timeout, :timed_out, changeset) do
    notify(changeset, :cancelled)
    {:next_state, :cancelled, changeset, timeout(:cancelled)}
  end

  def waiting({:call, from}, field, changeset) when field in @request_fields do
    gen_reply(changeset, field, :waiting, from)
  end

  def waiting({:call, from}, :get_order, changeset) do
    reply_order(changeset, :waiting, from)
  end

  def waiting({:call, from}, :num_items, changeset) do
    num_items =
      changeset
      |> Changeset.get_field(:items)
      |> Enum.map(& &1.quantity)
      |> Enum.sum()

    gen_reply(num_items, :waiting, from)
  end

  ## State: CANCELLED
  ## The order has been cancelled.
  def cancelled({:call, from}, :get_order, changeset) do
    reply_order(changeset, :cancelled, from)
  end

  def cancelled({:call, from}, :num_items, changeset) do
    num_items =
      changeset
      |> Changeset.get_field(:items)
      |> Enum.map(& &1.quantity)
      |> Enum.sum()

    gen_reply(num_items, :cancelled, from)
  end

  def cancelled(:timeout, :stop, _changeset) do
    :stop
  end

  ## State: PAID
  ## The order has been paid correctly.

  def paid({:call, from}, :get_order, changeset) do
    reply_order(changeset, :paid, from)
  end

  def paid({:call, from}, :num_items, changeset) do
    num_items =
      changeset
      |> Changeset.get_field(:items)
      |> Enum.map(& &1.quantity)
      |> Enum.sum()

    gen_reply(num_items, :waiting, from)
  end

  def paid({:call, from}, :expired?, changeset) do
    changeset
    |> Changeset.apply_changes()
    |> Order.expired?()
    |> gen_reply(:paid, from)
  end

  def paid({:call, from}, :files, changeset) do
    changeset
    |> Changeset.apply_changes()
    |> Order.get_files()
    |> gen_reply(:paid, from)
  end

  def paid({:call, from}, field, changeset) when field in @request_fields do
    gen_reply(changeset, field, :paid, from)
  end

  def paid(:timeout, :stop, _changeset) do
    :stop
  end

  ## Internal functions

  defp reply_order(changeset, state, from) do
    changeset
    |> Changeset.apply_changes()
    |> maybe_preload_payment_option(state)
    |> Order.update_virtual_items()
    |> Order.update_virtual()
    |> gen_reply(state, from)
  end

  defp maybe_preload_payment_option(order, :paid) do
    Repo.preload(order, [:payment_option], force: true)
  end

  defp maybe_preload_payment_option(order, _state), do: order

  defp store(changeset) do
    case changeset.action do
      :insert -> Repo.insert!(changeset)
      :update -> Repo.update!(changeset)
    end
    |> Order.changeset(%{})
    |> Order.set_action(:update)
  end

  defp notify(changeset, event_name) when is_atom(event_name) do
    id = Changeset.get_field(changeset, :id)
    remote_ip = Changeset.get_field(changeset, :remote_ip)
    Cart.notify({event_name, id, remote_ip})
  end

  defp notify(changeset, event) do
    event
    |> Tuple.insert_at(1, Changeset.get_field(changeset, :id))
    |> Tuple.insert_at(2, Changeset.get_field(changeset, :remote_ip))
    |> Cart.notify()
  end

  defp gen_reply(return, state, from) do
    reply = {:reply, from, return}
    {:keep_state_and_data, [timeout(state), reply]}
  end

  defp gen_reply(changeset, field, state, from) do
    changeset
    |> Changeset.apply_changes()
    |> Order.preload()
    |> Map.get(field)
    |> gen_reply(state, from)
  end

  defp get_state_name(changeset) do
    Changeset.get_field(changeset, :state)
  end

  defp set_payment_id(changeset) do
    payment_id = Changeset.get_field(changeset, :payment_id)
    id = Changeset.get_field(changeset, :id)
    registry = Cart.registry_name()
    Registry.put_meta(registry, {:payment_id, payment_id}, id)
    changeset
  end

  defp set_token(changeset) do
    token = Changeset.get_field(changeset, :token)
    id = Changeset.get_field(changeset, :id)
    registry = Cart.registry_name()
    Registry.put_meta(registry, {:token, token}, id)
    changeset
  end

  defp timeout(:new), do: {:timeout, @time_drop_new, :drop}
  defp timeout(:waiting), do: {:timeout, @time_drop_waiting, :timed_out}
  defp timeout(_), do: {:timeout, @time_to_stop, :stop}
end
