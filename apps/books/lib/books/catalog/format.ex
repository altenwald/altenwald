defmodule Books.Catalog.Format do
  use TypedEctoSchema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Books.Cart.OrderItem
  alias Books.Catalog
  alias Books.Catalog.{Book, DigitalFile, Format}

  @formats ~w[
    digital
    paper
    presale
  ]a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:name, :price, :tax, :shipping]}

  typed_schema "formats" do
    field :name, Ecto.Enum, values: @formats, default: :digital
    field(:price, Money.Ecto.Type) :: Money.t()
    field :tax, :integer, default: 9
    field :shipping, :boolean, default: false
    field :enabled, :boolean, default: true
    belongs_to :book, Book
    has_many :files, DigitalFile
    has_many :order_items, OrderItem

    timestamps()
  end

  @required_fields ~w[ price book_id ]a
  @optional_fields ~w[ name shipping tax enabled ]a

  @doc false
  def changeset(%Format{} = format, attrs) do
    format
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def get_title(format) do
    "#{Catalog.get_book_title(format.book)} (#{format.name})"
  end

  def preload do
    from(f in __MODULE__, where: f.enabled)
  end
end
