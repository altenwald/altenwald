defmodule Books.Catalog.DigitalFile do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Books.Catalog.{DigitalFile, Format}

  @filetypes ~w[
    pdf
    epub
  ]a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "digital_files" do
    field :filename, :string
    field :description, :string
    field :filetype, Ecto.Enum, values: @filetypes
    field :enabled, :boolean, default: true
    belongs_to :format, Format

    timestamps()
  end

  @required_fields ~w[ filename description filetype format_id ]a
  @optional_fields ~w[ enabled ]a

  @doc false
  def changeset(%DigitalFile{} = digital_file, attrs) do
    digital_file
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
