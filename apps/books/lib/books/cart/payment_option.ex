defmodule Books.Cart.PaymentOption do
  use TypedEctoSchema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Books.Cart.PaymentOption
  alias Books.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "payment_options" do
    field :name, :string
    field :slug, :string
    field(:amount, Money.Ecto.Type) :: Money.t()
    field :enabled, :boolean, default: true

    timestamps()
  end

  def encode_token(order_id) do
    order_id
    |> String.split("-")
    |> List.last()
  end

  def all do
    from(p in PaymentOption, where: p.enabled)
    |> Repo.all()
  end

  def get_by_slug(slug) do
    Repo.get_by(PaymentOption, slug: slug)
  end

  def get_slug_by_id(id) do
    case Repo.get(PaymentOption, id) do
      nil -> nil
      %PaymentOption{slug: slug} -> slug
    end
  end

  @required_fields ~w[ name slug enabled ]a
  @optional_fields ~w[ amount ]a

  @doc false
  def changeset(payment_option, attrs) do
    payment_option
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
