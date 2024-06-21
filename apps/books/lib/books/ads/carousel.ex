defmodule Books.Ads.Carousel do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Ads.Bundle
  alias Books.Catalog.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "ads_carousel" do
    field :enable, :boolean, default: false
    field :priority, :integer, default: 1
    field :image, :string
    field :type, Ecto.Enum, values: ~w[book bundle]a
    belongs_to :book, Book
    belongs_to :bundle, Bundle

    timestamps()
  end

  @required_fields ~w[ image type ]a
  @optional_fields ~w[ book_id bundle_id enable priority ]a

  @doc false
  def changeset(carousel, attrs) do
    carousel
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_cond_required(:type, book: [:book_id], bundle: [:bundle_id])
  end

  defp validate_cond_required(changes, field, all_fields) do
    with key when key != nil <- get_field(changes, field),
         fields when fields != nil <- all_fields[key] do
      validate_required(changes, fields)
    else
      nil -> changes
    end
  end
end
