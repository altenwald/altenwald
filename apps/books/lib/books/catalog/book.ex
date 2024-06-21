defmodule Books.Catalog.Book do
  use TypedEctoSchema
  import Ecto.Query, only: [from: 2]
  import Ecto.Changeset

  alias Books.Balances.Income

  alias Books.Catalog.{
    BookAuthor,
    BookCrossSelling,
    Category,
    Content,
    Format,
    Project,
    Review
  }

  alias Books.Catalog.Book.ShopLink
  alias Books.Engagement.VisualAlert
  alias Books.Landings.Landing
  alias Books.Posts.{BookPost, Post}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:title, :subtitle, :description]}

  typed_schema "books" do
    field :slug, :string
    field :title, :string
    field :subtitle, :string
    field :description, :string
    field :keywords, :string
    field :marketing_description, :string
    field :resources_url, :string
    field :edition, :integer, default: 1

    field :enabled, :boolean
    field :presale, :date
    field :release, :date

    field(:income, Money.Ecto.Type, default: Money.new(0), virtual: true) :: Money.t()

    field :num_pages, :integer
    field :isbn, :string
    field :legal_deposit, :string

    embeds_many :shop_links, ShopLink, on_replace: :delete

    field :lang, :string, default: "es"

    has_many :roles, BookAuthor
    has_many :cross_sellings, BookCrossSelling
    has_many :formats, Format
    has_many :contents, Content
    has_many :projects, Project
    has_one :landing, Landing
    has_many :reviews, Review
    has_many :incomes, Income
    has_many :visual_alerts, VisualAlert
    belongs_to :category, Category
    many_to_many :posts, Post, join_through: BookPost

    timestamps()
  end

  @optional_fields ~w[
    resources_url
    num_pages
    isbn
    legal_deposit
    presale
    release
    lang
    edition
  ]a
  @required_fields ~w[
    enabled
    slug
    title
    subtitle
    description
    keywords
    marketing_description
    category_id
  ]a

  @doc false
  def changeset(%__MODULE__{} = book, attrs) do
    book
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast_embed(:shop_links)
    |> validate_required(@required_fields)
    |> unsafe_validate_unique([:slug], Books.Repo)
    |> unique_constraint([:slug])
  end

  def preload(full_preload \\ false)

  def preload(false) do
    [
      :category,
      :projects,
      :reviews,
      :posts,
      :visual_alerts,
      contents: Content.preload(),
      cross_sellings:
        from(
          bcs in BookCrossSelling,
          join: b in assoc(bcs, :book_crossed),
          where: b.enabled,
          preload: [book_crossed: [formats: ^Format.preload(), roles: :author]]
        ),
      roles: :author,
      formats: Format.preload()
    ]
  end

  def preload(true) do
    [
      :category,
      :projects,
      :reviews,
      :posts,
      :visual_alerts,
      :formats,
      contents: Content.preload(),
      cross_sellings:
        from(
          bcs in BookCrossSelling,
          join: b in assoc(bcs, :book_crossed),
          preload: [book_crossed: [:formats, roles: :author]]
        ),
      roles: :author
    ]
  end
end
