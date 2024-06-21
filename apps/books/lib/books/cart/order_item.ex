defmodule Books.Cart.OrderItem do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Ads.Offer
  alias Books.Catalog.Format
  alias Books.{Repo, Tax}
  alias Books.Cart.{Order, OrderItem}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "order_items" do
    belongs_to :order, Order
    belongs_to :format, Format
    field :quantity, :integer, default: 1

    field(:total_items, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:subtotal, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:tax, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field :discount_display, :string, virtual: true, default: "0€"
    field :discount_percentage, :integer, virtual: true, default: 0
    field(:discount_total, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:total, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:final_price, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:tax_price, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()
    field(:price, Money.Ecto.Type, virtual: true, default: Money.new(0)) :: Money.t()

    timestamps()
  end

  @doc false
  def changeset(%OrderItem{} = order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity])
    |> validate_required([:quantity])
  end

  def add(items, format_id, order) do
    if old_item = Enum.find(items, &(&1.format_id == format_id)) do
      if old_item.format.name != :paper do
        ## new item for a different format than paper is ignored
        items
      else
        ##  a new item to add (which should be paper)
        new_item =
          %OrderItem{old_item | quantity: old_item.quantity + 1}
          |> update_virtual(order)

        Enum.sort([new_item | items -- [old_item]])
      end
    else
      ##  first item for this format in the order
      item =
        %OrderItem{format_id: format_id, quantity: 1}
        |> Repo.preload(format: [:book])
        |> update_virtual(order)

      Enum.sort([item | items])
    end
  end

  def rem(items, format_id, order) do
    filter = for i <- items, i.format_id == format_id, do: i

    case filter do
      [] ->
        items

      [%OrderItem{quantity: 1} = old_item] ->
        items -- [old_item]

      [old_item] ->
        new_item =
          %OrderItem{old_item | quantity: old_item.quantity - 1}
          |> update_virtual(order)

        Enum.sort([new_item | items -- [old_item]])
    end
  end

  def update_virtual(item, order) do
    {discount_display, discount_percentage, final_price} =
      get_price_with_discount(item, order.offers)

    subtotal = Money.multiply(item.format.price, item.quantity)
    total = Money.multiply(final_price, item.quantity)
    discount_total = Money.subtract(total, subtotal)
    tax = Tax.get_amount(total, order.country)
    tax_price = Tax.get_amount(final_price, order.country)
    subtotal = Money.subtract(total, tax)
    price = Money.subtract(final_price, tax_price)

    %OrderItem{
      item
      | total_items: subtotal,
        discount_display: discount_display,
        discount_percentage: discount_percentage,
        discount_total: discount_total,
        subtotal: subtotal,
        tax: tax,
        total: total,
        tax_price: tax_price,
        final_price: final_price,
        price: price
    }
  end

  defp get_price_with_discount(item, offers) do
    offer =
      if is_list(offers) do
        for offer <- offers,
            apply_format <- offer.applies,
            apply_format.id == item.format_id,
            do: offer
      else
        []
      end

    case offer do
      [%Offer{discount_type: :percentage, discount_amount: amount} | _] ->
        discount =
          item.format.price
          |> Money.multiply(amount / 100)

        money = Money.subtract(item.format.price, discount)
        {"-#{amount}%", amount, money}

      [%Offer{discount_type: :money, discount_amount: amount} | _] ->
        perc = amount * 100 / item.format.price.amount
        money = Money.subtract(item.format.price, amount)
        {"-#{Money.new(amount)}", perc, money}

      [] ->
        {"", 0, item.format.price}
    end
  end
end
