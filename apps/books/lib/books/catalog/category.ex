defmodule Books.Catalog.Category do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Catalog.{Book, Category}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:name, :color, :description]}

  typed_schema "categories" do
    field :name, :string
    field :color, :string
    field :description, {:map, :string}
    has_many :books, Book

    timestamps()
  end

  @required_fields ~w[ name ]a
  @optional_fields ~w[ color description ]a

  @doc false
  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unsafe_validate_unique([:name], Books.Repo)
    |> unique_constraint([:name])
  end
end
