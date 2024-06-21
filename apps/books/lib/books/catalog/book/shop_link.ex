defmodule Books.Catalog.Book.ShopLink do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  typed_embedded_schema do
    field :id, :string, primary_key: true
    field :type, Ecto.Enum, values: [:digital, :paper], default: :digital
    field :name, :string
    field :url, :string
  end

  @required_fields ~w[id name type url]a
  @optional_fields ~w[]a

  def changeset(%__MODULE__{} = shop_link, attrs) do
    shop_link
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
