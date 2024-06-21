defmodule Books.Accounts.Role do
  use TypedEctoSchema

  import Ecto.Changeset

  alias Books.Accounts.User

  @roles ~w[ author admin ]a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "roles" do
    field :name, Ecto.Enum, values: @roles

    belongs_to :user, User
    timestamps()
  end

  @required_fields ~w[ name ]a
  @optional_fields ~w[ user_id ]a

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end
end
