defmodule Books.Ads.BundleFormat do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Ads.Bundle
  alias Books.Catalog.Format

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "bundle_formats" do
    belongs_to :bundle, Bundle
    belongs_to :format, Format
    timestamps()
  end

  @doc false
  def changeset(model, params) do
    model
    |> cast(params, [:bundle_id, :format_id])
    |> validate_required([:format_id])
  end
end
