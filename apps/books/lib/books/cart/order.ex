defmodule Books.Cart.Order do
  use TypedEctoSchema
  require Logger

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Books.Ads.Offer
  alias Books.{Repo, Shipping}
  alias Books.Cart.{Order, OrderItem, OrderOffer, PaymentOption}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Let download the files only 24 hours
  @hours_to_expire 24

  @preload_relations [
    :payment_option,
    offers: [:applies],
    items: [format: [:book, :files]]
  ]

  @expires 24 * 3600 * -1
  @timedout 7 * 24 * 3600 * -1

  @order_states ~w[ new waiting paid cancelled timed-out refunded ]a
  @shipping_status ~w[ not-applicable new preparing sent received ]a

  typed_schema "orders" do
    field :state, Ecto.Enum, values: @order_states, default: :new
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :remote_ip, :string
    field :country, :string
    field :accept_tos, :boolean
    has_many :items, OrderItem
    many_to_many :offers, Offer, join_through: OrderOffer, on_replace: :delete

    field :download_expires_at, :utc_datetime

    field :shipping_address, :string
    field :shipping_postal_code, :string
    field :shipping_city, :string
    field :shipping_state, :string
    field :shipping_country, :string
    field :shipping_phone, :string
    field(:shipping_amount, Money.Ecto.Type) :: Money.t()
    field :shipping_status, Ecto.Enum, values: @shipping_status
    field :shipping_status_at, :date
    field :shipping_tracking_url, :string

    field :shipping?, :boolean, virtual: true, default: false
    field :digital?, :boolean, virtual: true, default: false
    field :presale?, :boolean, virtual: true, default: false

    field(:items_total, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:items_subtotal, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:tax, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:shipping_subtotal, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:shipping_discount, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:shipping_total, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:total_price, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()

    field :shipping_items, :integer, virtual: true, default: 0

    belongs_to :payment_option, PaymentOption
    field :payment_id, :string
    field :token, :string
    field :payer_email, :string
    field :payer_first_name, :string
    field :payer_last_name, :string

    timestamps()
  end

  @fields ~w[
    state
    first_name
    last_name
    email
    remote_ip
    country
    shipping_address
    shipping_postal_code
    shipping_city
    shipping_state
    shipping_country
    token
    shipping_phone
    shipping_amount
    payment_id
    payer_email
    payer_first_name
    payer_last_name
    accept_tos
    payment_option_id
    shipping_status
    shipping_status_at
    shipping_tracking_url
    download_expires_at
  ]a
  @required_fields_shipping ~w[
    state
    first_name
    last_name
    email
    remote_ip
    country
    shipping_address
    shipping_postal_code
    shipping_amount
    shipping_city
    shipping_state
    shipping_country
    shipping_phone
    payment_option_id
  ]a
  @required_fields_digital ~w[
    state
    first_name
    last_name
    email
    remote_ip
    country
    payment_option_id
  ]a

  defp validate_if_required(changes, field, true_fields, false_fields) do
    if get_field(changes, field) do
      validate_required(changes, true_fields)
    else
      validate_required(changes, false_fields)
    end
  end

  @doc false
  def changeset(attrs) do
    %Order{}
    |> preload()
    |> changeset(attrs)
  end

  defp reset_changeset(changeset) do
    %Ecto.Changeset{changeset | errors: [], valid?: true}
  end

  def changeset(%Ecto.Changeset{valid?: false} = changeset, attrs) do
    changeset
    |> reset_changeset()
    |> changeset(attrs)
  end

  def changeset(nil, attrs), do: changeset(attrs)

  def changeset(order, attrs) do
    order
    |> cast(attrs, @fields)
    |> validate_acceptance_if_new(:accept_tos)
    |> validate_if_required(:shipping?, @required_fields_shipping, @required_fields_digital)
    |> update_virtual()
  end

  def validate_acceptance_if_new(changeset, field) do
    if get_field(changeset, :state) == :new do
      validate_acceptance(changeset, field)
    else
      changeset
    end
  end

  def clean_orders do
    date = NaiveDateTime.add(NaiveDateTime.utc_now(), @expires)

    from(o in Order,
      where: o.updated_at < ^date and o.state == :new
    )
    |> Repo.update_all(set: [state: :cancelled])

    date = NaiveDateTime.add(NaiveDateTime.utc_now(), @timedout)

    from(o in Order,
      where: o.updated_at < ^date and o.state == :waiting
    )
    |> Repo.update_all(set: [state: :"timed-out"])
  end

  def update_virtual(%Order{} = order) do
    shipping_items =
      order.items
      |> Stream.filter(& &1.format.shipping)
      |> Stream.map(& &1.quantity)
      |> Enum.sum()

    shipping? = shipping_items > 0
    digital? = shipping_items != length(order.items)
    presale? = Enum.any?(order.items, &(&1.format.name == :presale))
    zero = Money.new(0)

    {shipping_subtotal, shipping_discount, shipping_total} =
      if shipping? do
        amount = Shipping.get_amount(order.shipping_country)
        subtotal = Money.multiply(amount, div(shipping_items, 4) + 1)
        discount = shipping_discount(order, subtotal)
        total = Money.subtract(subtotal, discount)
        {subtotal, discount, total}
      else
        {zero, zero, zero}
      end

    {subtotal_items, tax, total_items} = get_total_data(order)
    total = Money.add(total_items, shipping_total)

    %Order{
      order
      | shipping?: shipping?,
        digital?: digital?,
        presale?: presale?,
        items_total: total_items,
        items_subtotal: subtotal_items,
        tax: tax,
        shipping_subtotal: shipping_subtotal,
        shipping_total: shipping_total,
        shipping_discount: shipping_discount,
        shipping_items: shipping_items,
        total_price: total
    }
  end

  def update_virtual(nil), do: nil

  def update_virtual(changeset) do
    order =
      changeset
      |> apply_changes()
      |> update_virtual()

    ~w[
      shipping?
      digital?
      presale?
      items_total
      items_subtotal
      tax
      shipping_subtotal
      shipping_total
      shipping_discount
      shipping_items
      total_price
    ]a
    |> Enum.reduce(changeset, &put_change(&2, &1, Map.get(order, &1)))
  end

  def update_virtual_items(nil), do: nil

  def update_virtual_items(order) do
    items = Enum.map(order.items, &OrderItem.update_virtual(&1, order))
    Map.put(order, :items, items)
  end

  def set_action(changeset, action) do
    ## TODO: this should to be done in another way, I'm sure!
    %Ecto.Changeset{changeset | action: action}
  end

  def preload_relations, do: @preload_relations

  def preload(%Order{} = order) do
    Repo.preload(order, @preload_relations, force: true)
  end

  def preload(%Ecto.Changeset{data: order} = changeset) do
    Map.put(changeset, :data, preload(order))
  end

  defp shipping_discount(order, subtotal) do
    case for(o <- order.offers, o.discount_type == :shipping, do: o) do
      [] -> Money.new(0)
      [offer] -> Money.multiply(subtotal, (100 - offer.discount_amount) / 100)
    end
  end

  defp sum_up(item, {subtotal, tax, total}) do
    {
      Money.add(subtotal, item.subtotal),
      Money.add(tax, item.tax),
      Money.add(total, item.total)
    }
  end

  def get_files(order) do
    order
    |> preload()
    |> Map.get(:items)
    |> Enum.flat_map(& &1.format.files)
    |> Enum.sort()
    |> Enum.uniq()
  end

  defp get_total_data(order) do
    acc = {Money.new(0), Money.new(0), Money.new(0)}
    Enum.reduce(order.items, acc, &sum_up/2)
  end

  def expired?(%Order{download_expires_at: nil, inserted_at: datetime}) do
    expired?(datetime)
  end

  def expired?(%Order{download_expires_at: datetime}) do
    datetime
    |> DateTime.to_naive()
    |> expired?()
  end

  def expired?(nil), do: true

  def expired?(datetime) do
    hours =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.diff(datetime)
      |> div(3600)

    hours > @hours_to_expire
  end
end
