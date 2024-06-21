defmodule Books.Landings.Feature do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Landings.{Feature, Landing}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "landing_features" do
    field :title, :string
    field :content, :string
    field :icon, :string
    belongs_to :landing, Landing

    timestamps()
  end

  @required_fields ~w[ title content landing_id ]a
  @optional_fields ~w[ icon ]a

  @doc false
  def changeset(%Feature{} = feature, attrs) do
    feature
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
