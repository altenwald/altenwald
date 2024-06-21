defmodule Books.Cart.OrderOffer do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Ads.Offer
  alias Books.Cart.Order

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "order_offers" do
    belongs_to :order, Order
    belongs_to :offer, Offer

    timestamps()
  end

  @doc false
  def changeset(order_offer, attrs) do
    order_offer
    |> cast(attrs, [:order_id, :offer_id])
    |> validate_required([:order_id, :offer_id])
  end
end
