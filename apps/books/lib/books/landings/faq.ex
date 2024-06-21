defmodule Books.Landings.FAQ do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Landings.{FAQ, Landing}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "landing_faqs" do
    field :question, :string
    field :answer, :string
    belongs_to :landing, Landing

    timestamps()
  end

  @required_fields ~w[ question answer landing_id ]a
  @optional_fields ~w[]a

  @doc false
  def changeset(%FAQ{} = faq, attrs) do
    faq
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
