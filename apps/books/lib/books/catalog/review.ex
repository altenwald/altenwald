defmodule Books.Catalog.Review do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Catalog.{Book, Review}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "book_reviews" do
    field :full_name, :string
    field :position, :string
    field :company, :string
    field :content, :string
    field :value, :integer
    belongs_to :book, Book

    timestamps()
  end

  @required_fields ~w[ full_name content book_id ]a
  @optional_fields ~w[ position company value ]a

  @doc false
  def changeset(%Review{} = review, attrs) do
    review
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
