defmodule Books.Catalog.Project do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Catalog.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "projects" do
    field :description, :string
    field :logo, :string
    field :name, :string
    field :url, :string
    belongs_to :book, Book

    timestamps()
  end

  @required_fields ~w[ name description logo url book_id ]a
  @optional_fields ~w[]a

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
