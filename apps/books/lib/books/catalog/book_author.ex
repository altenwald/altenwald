defmodule Books.Catalog.BookAuthor do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Catalog.{Author, Book, BookAuthor}

  @roles ~w[
    author
    translator
    reviewer
    editor
    illustrator
  ]a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:role]}

  typed_schema "book_authors" do
    field :role, Ecto.Enum, values: @roles, default: :author
    belongs_to :book, Book
    belongs_to :author, Author

    timestamps()
  end

  @required_fields ~w[ role book_id author_id ]a
  @optional_fields []

  @doc false
  def changeset(%BookAuthor{} = book_author, attrs) do
    book_author
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
