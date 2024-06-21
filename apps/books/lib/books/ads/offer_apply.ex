defmodule Books.Ads.OfferApply do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Ads.Offer
  alias Books.Catalog.Format

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "offer_applies" do
    belongs_to :format, Format
    belongs_to :offer, Offer

    timestamps()
  end

  @doc false
  def changeset(offer_apply, attrs) do
    offer_apply
    |> cast(attrs, [:format_id, :offer_id])
  end
end
