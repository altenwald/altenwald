defmodule Books.Landings.Landing do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Ads.Bundle
  alias Books.Catalog.Book
  alias Books.Landings.{FAQ, Feature, Landing}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "landings" do
    field :enable, :boolean, default: false
    field :lang, :string, default: "es"
    field :slugs, {:array, :string}
    field :description, :string
    field :about, :string
    field :engagement_phrases, {:array, :string}
    field :preview_pages, :integer, default: 0
    belongs_to :book, Book
    belongs_to :bundle, Bundle

    has_many :features, Feature
    has_many :faqs, FAQ

    timestamps()
  end

  @required_fields ~w[ description about engagement_phrases slugs ]a
  @optional_fields ~w[ enable preview_pages lang book_id bundle_id ]a

  @doc false
  def changeset(%Landing{} = landing, attrs) do
    landing
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_only_one([:book_id, :bundle_id])
  end

  defp validate_only_one(changeset, fields) do
    fields
    |> Enum.reject(&is_nil(get_field(changeset, &1)))
    |> case do
      [_] -> changeset
      [] -> validate_required(changeset, fields)
      fields -> Enum.reduce(fields, changeset, &add_error(&2, &1, "cannot set both"))
    end
  end
end
