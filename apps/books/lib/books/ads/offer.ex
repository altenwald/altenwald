defmodule Books.Ads.Offer do
  use TypedEctoSchema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Books.Ads.{FormatOffer, Offer, OfferApply, OfferGroup}
  alias Books.Cart.OrderOffer
  alias Books.Catalog.Format
  alias Books.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "offers" do
    field :name, :string
    field :type, Ecto.Enum, values: ~w[ code combo time ]a
    field :code, :string
    field :discount_amount, :integer
    field :discount_type, Ecto.Enum, values: ~w[ money percentage shipping ]a
    field :expiration, :utc_datetime
    field :max_uses, :integer
    belongs_to :offer_group, OfferGroup
    many_to_many :formats, Format, join_through: "format_offers"
    many_to_many :applies, Format, join_through: "offer_applies"

    field :uses, :integer, default: 0, virtual: true

    has_many :format_offers, FormatOffer, on_delete: :delete_all, on_replace: :delete
    has_many :offer_applies, OfferApply, on_delete: :delete_all, on_replace: :delete
    has_many :order_offers, OrderOffer
    timestamps()
  end

  @required_fields ~w[ name discount_type discount_amount type ]a
  @optional_fields ~w[ code expiration max_uses offer_group_id ]a

  @doc false
  def changeset(offer \\ %Offer{}, attrs \\ %{}) do
    offer
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:format_offers)
    |> cast_assoc(:offer_applies)
    |> validate_required(@required_fields)
  end

  def delete_changeset(offer) do
    offer
    |> change()
    |> foreign_key_constraint(:order_offers, name: :order_offers_offer_id_fkey1)
  end

  def search_offer(format_ids) do
    now = NaiveDateTime.utc_now()

    from(o in Offer,
      where:
        fragment(
          "?::text[] @> (array(SELECT format_id FROM format_offers WHERE offer_id = o0.id))::text[]",
          ^format_ids
        ) and
          o.type == :combo and
          (o.expiration > ^now or is_nil(o.expiration)),
      preload: [:applies],
      order_by: [desc: :inserted_at],
      limit: 1
    )
    |> Repo.all()
  end
end
