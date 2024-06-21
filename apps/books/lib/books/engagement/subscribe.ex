defmodule Books.Engagement.Subscribe do
  use TypedEctoSchema

  import Ecto.Changeset

  require Logger

  alias Books.Engagement.Subscribe

  @primary_key false
  typed_embedded_schema do
    field :full_name, :string
    field :email, :string
  end

  @required_fields ~w[ full_name email ]a
  @optional_fields ~w[]a

  def changeset(attrs) do
    %Subscribe{}
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_email()
    |> apply_action(:update)
  end

  def changeset do
    cast(%Subscribe{}, %{}, [])
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end
end
