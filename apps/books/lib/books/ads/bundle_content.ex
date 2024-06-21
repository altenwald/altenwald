defmodule Books.Ads.BundleContent do
  use TypedEctoSchema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Books.Ads.Bundle

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:order, :title, :description]}

  typed_schema "bundle_contents" do
    field :description, :string
    field :excerpt_filename, :string
    field :order, :integer
    field :title, :string
    belongs_to :bundle, Bundle

    timestamps()
  end

  @required_fields ~w[bundle_id title description]a
  @optional_fields ~w[order excerpt_filename]a

  @doc false
  def changeset(%__MODULE__{} = content, attrs) do
    content
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def preload do
    from(c in __MODULE__, order_by: [c.order])
  end
end
