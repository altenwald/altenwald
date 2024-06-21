defmodule Books.Posts.Post do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Catalog.{Author, Book}
  alias Books.Posts.{BookPost, Category, Comment, PostTag, Tag}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "posts" do
    field :background_image, :string
    field :content, :string
    field :excerpt, :string
    field :featured_image, :string
    field :slug, :string
    field :subtitle, :string
    field :title, :string
    field :lang, :string, default: "es"
    field :private, :boolean, default: false
    belongs_to :author, Author
    belongs_to :category, Category

    field :tags_text, :string, virtual: true

    has_many :comments, Comment
    many_to_many :tags, Tag, join_through: PostTag
    many_to_many :books, Book, join_through: BookPost
    timestamps()
  end

  @required_fields ~w[ slug title content author_id category_id ]a
  @optional_fields ~w[ background_image featured_image excerpt subtitle lang private inserted_at updated_at tags_text ]a

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> maybe_put_assoc(:tags, attrs["tags"])
    |> maybe_put_assoc(:books, attrs["books"])
    |> validate_required(@required_fields)
  end

  defp maybe_put_assoc(changeset, _name, nil), do: changeset

  defp maybe_put_assoc(changeset, name, values) do
    put_assoc(changeset, name, values)
  end
end
