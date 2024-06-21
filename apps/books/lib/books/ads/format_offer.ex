defmodule Books.Ads.FormatOffer do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Ads.Offer
  alias Books.Catalog.Format

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "format_offers" do
    belongs_to :format, Format
    belongs_to :offer, Offer

    timestamps()
  end

  @doc false
  def changeset(format_offer, attrs) do
    format_offer
    |> cast(attrs, [:format_id, :offer_id])
    |> validate_required([])
  end
end
