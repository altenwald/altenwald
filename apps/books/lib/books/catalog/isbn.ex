defmodule Books.Catalog.Isbn do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Catalog.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "isbns" do
    field :isbn, :string
    field :tipo_obra, :string
    field :titulo, :string
    field :status, :string

    belongs_to :book, Book

    timestamps()
  end

  @doc false
  def changeset(isbn, attrs) do
    isbn
    |> cast(attrs, [:tipo_obra, :isbn, :titulo, :status, :book_id])
    |> validate_required([:tipo_obra, :isbn, :status])
    |> validate_inclusion(:status, ~w[assigned free reserved])
  end

  defimpl String.Chars, for: __MODULE__ do
    def to_string(%Books.Catalog.Isbn{} = isbn) do
      "#ISBN<#{isbn.isbn}>"
    end
  end
end
