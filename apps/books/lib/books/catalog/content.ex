defmodule Books.Catalog.Content do
  use TypedEctoSchema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Books.Catalog.{Book, Content}

  @status_values ~w[
    todo
    prepared
    reviewed
    done
  ]a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:chapter_type, :order, :title, :description, :status]}

  typed_schema "contents" do
    field :chapter_type, :string
    field :description, :string
    field :excerpt_filename, :string
    field :order, :integer
    field :title, :string
    field :status, Ecto.Enum, default: :done, values: @status_values
    belongs_to :book, Book

    timestamps()
  end

  @doc false
  def changeset(%Content{} = content, attrs) do
    content
    |> cast(attrs, [
      :book_id,
      :chapter_type,
      :order,
      :title,
      :description,
      :excerpt_filename,
      :status
    ])
    |> validate_required([:book_id, :chapter_type, :title, :description, :status])
  end

  def preload do
    from(c in __MODULE__, order_by: [c.chapter_type, c.order])
  end
end
