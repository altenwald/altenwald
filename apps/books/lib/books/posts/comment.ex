defmodule Books.Posts.Comment do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Accounts.User
  alias Books.Posts.{Comment, Post}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "post_comments" do
    field :content, :string
    belongs_to :user, User
    belongs_to :post, Post
    belongs_to :parent, Comment, foreign_key: :parent_id

    timestamps()
  end

  @required_fields ~w[ content post_id user_id ]a
  @optional_fields ~w[ parent_id ]a

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
