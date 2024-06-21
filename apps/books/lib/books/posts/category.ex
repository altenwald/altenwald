defmodule Books.Posts.Category do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "post_categories" do
    field :name, {:map, :string}
    field :color, :string

    timestamps()
  end

  @required_fields ~w[ name color ]a
  @optional_fields ~w[]a

  @doc false
  def changeset(post_category, attrs) do
    post_category
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
