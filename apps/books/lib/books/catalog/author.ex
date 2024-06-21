defmodule Books.Catalog.Author do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Accounts.User
  alias Books.Catalog.Author

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:full_name]}

  typed_schema "authors" do
    field :full_name, :string
    field :short_name, :string
    field :description, {:map, :string}
    field :title, {:map, :string}
    field :urls, {:map, :string}, default: %{"personal" => ""}

    belongs_to :user, User
    timestamps()
  end

  @required_fields ~w[ full_name short_name ]a
  @optional_fields ~w[ description title urls user_id ]a

  @doc false
  def changeset(%Author{} = author, attrs) do
    attrs =
      if urls = attrs["urls"] do
        if urls["personal"] do
          attrs
        else
          Map.put(attrs, "urls", Map.put(urls, "personal", ""))
        end
      else
        attrs
      end

    author
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
