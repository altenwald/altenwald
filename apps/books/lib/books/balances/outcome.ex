defmodule Books.Balances.Outcome do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Catalog.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "outcome" do
    field :target, :string
    field :items, :integer, default: 0
    field(:amount, Money.Ecto.Type, default: Money.new(0)) :: Money.t()
    field :month, :integer
    field :year, :integer
    belongs_to :book, Book

    timestamps()
  end

  @required_fields ~w[ month year target ]a
  @optional_fields ~w[ items amount book_id ]a

  @doc false
  def changeset(outcome, attrs) do
    outcome
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
