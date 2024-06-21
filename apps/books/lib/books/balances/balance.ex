defmodule Books.Balances.Balance do
  use TypedEctoSchema

  alias Books.Catalog.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "balances" do
    field :type, Ecto.Enum, values: ~w[ income outcome ]a
    field :month, :integer
    field :year, :integer
    field :items, :integer, default: 0
    field(:amount, Money.Ecto.Type, default: Money.new(0)) :: Money.t()
    field :name, :string
    belongs_to :book, Book

    timestamps()
  end
end
