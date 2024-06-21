defmodule Books.Engagement.VisualAlert do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Books.Catalog.Book

  @types ~w[
    primary
    default
    success
    danger
    warning
    info
    light
    dark
  ]a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "visual_alerts" do
    field :enabled, :boolean, default: true
    field :body, :string
    field :lang, :string, default: "es"
    field :title, :string
    field :type, Ecto.Enum, values: @types, default: :default
    belongs_to :book, Book

    timestamps()
  end

  @required_fields ~w[title body]a
  @optional_fields ~w[enabled lang type book_id]a

  @doc false
  def changeset(visual_alert, attrs) do
    visual_alert
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
