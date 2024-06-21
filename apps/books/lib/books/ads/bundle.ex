defmodule Books.Ads.Bundle do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Ads.BundleContent
  alias Books.Ads.BundleFormat
  alias Books.Catalog.Format

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "bundles" do
    field :slug, :string
    field :enabled, :boolean, default: false
    field :lang, :string, default: "es"
    field :name, :string
    field :description, :string
    field :keywords, :string
    field(:real_price, Money.Ecto.Type) :: Money.t()
    field(:price, Money.Ecto.Type) :: Money.t()
    many_to_many :formats, Format, join_through: "bundle_formats"
    has_many :bundle_formats, BundleFormat, on_delete: :delete_all, on_replace: :delete
    has_many :contents, BundleContent, on_delete: :delete_all, on_replace: :delete
    timestamps()
  end

  @required_fields ~w[slug name description keywords price real_price]a
  @optional_fields ~w[enabled lang]a

  @doc false
  def changeset(model, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_assoc(:bundle_formats)
    |> cast_assoc(:contents)
    |> validate_required(@required_fields)
    |> unique_constraint(:slug)
  end
end
