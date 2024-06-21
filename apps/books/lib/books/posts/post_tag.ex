defmodule Books.Posts.PostTag do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Posts.{Post, Tag}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "post_tags" do
    belongs_to :post, Post
    belongs_to :tag, Tag

    timestamps()
  end

  @required_fields ~w[]a
  @optional_fields ~w[ post_id tag_id ]a

  @doc false
  def changeset(post_tag, attrs) do
    post_tag
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
