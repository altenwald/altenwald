defmodule Books.Accounts.BookshelfItem do
  use TypedEctoSchema

  import Ecto.Changeset

  alias Books.Accounts.User
  alias Books.Cart.Order
  alias Books.Catalog.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @types ~w[ purchased external author ]a

  typed_schema "bookshelf_items" do
    field :type, Ecto.Enum, values: @types
    field :description, :string
    field :started_at, :date
    field :expires_at, :date

    belongs_to :user, User
    belongs_to :book, Book
    belongs_to :order, Order

    timestamps()
  end

  @required_fields ~w[ type description started_at user_id book_id ]a
  @optional_fields ~w[ order_id expires_at ]a

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :book_id])
  end
end
