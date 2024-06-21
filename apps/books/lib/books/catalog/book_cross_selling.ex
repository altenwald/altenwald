defmodule Books.Catalog.BookCrossSelling do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Catalog.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:description, :lang]}

  typed_schema "book_cross_sellings" do
    field :description, :string
    field :lang, :string, default: "es"
    belongs_to :book, Book
    belongs_to :book_crossed, Book, foreign_key: :book_crossed_id

    timestamps()
  end

  @required_fields ~w[ description book_id book_crossed_id ]a
  @optional_fields ~w[ lang ]a

  @doc false
  def changeset(book_cross_selling, attrs) do
    book_cross_selling
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_different_values(:book_id, :book_crossed_id)
  end

  def validate_different_values(changeset, book_id1, book_id2) do
    if get_field(changeset, book_id1) == get_field(changeset, book_id2) do
      changeset
      |> add_error(book_id1, "must be different from the other book")
      |> add_error(book_id2, "must be different from the other book")
    else
      changeset
    end
  end
end
