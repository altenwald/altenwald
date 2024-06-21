defmodule Books.Posts.BookPost do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Catalog.Book
  alias Books.Posts.Post

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "book_posts" do
    belongs_to :book, Book
    belongs_to :post, Post

    timestamps()
  end

  @required_fields ~w[ post_id book_id ]a
  @optional_fields ~w[]a

  @doc false
  def changeset(book_post, attrs) do
    book_post
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
