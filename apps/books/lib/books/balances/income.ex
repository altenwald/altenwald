defmodule Books.Balances.Income do
  use TypedEctoSchema
  require Logger

  import Ecto.Changeset

  alias Books.Catalog.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @default_source "Altenwald"

  typed_schema "income" do
    field :month, :integer
    field :year, :integer
    field :items, :integer, default: 0
    field(:amount, Money.Ecto.Type, default: Money.new(0)) :: Money.t()
    field :source, :string, default: @default_source
    belongs_to :book, Book

    timestamps()
  end

  @required_fields ~w[ month year ]a
  @optional_fields ~w[ items amount source book_id ]a

  def default_source, do: @default_source

  @doc false
  def changeset(income, attrs) do
    income
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
