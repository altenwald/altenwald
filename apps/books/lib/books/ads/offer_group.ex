defmodule Books.Ads.OfferGroup do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Ads.Offer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "offer_groups" do
    field :name, :string
    has_many :offers, Offer
    timestamps()
  end

  @required_fields ~w[name]a
  @optional_fields ~w[]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
  end
end
