defmodule Books.Repo.Migrations.CreateLanding do
  use Ecto.Migration

  def change do
    create table(:landings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :enable, :boolean
      add :description, :text
      add :about, :text
      add :engagement_phrases, {:array, :string}
      add :book_id, references(:books, on_delete: :delete_all, type: :binary_id)
      timestamps()
    end

    create unique_index(:landings, [:book_id])

    create table(:landing_features, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :content, :text
      add :icon, :string
      add :landing_id, references(:landings, on_delete: :delete_all, type: :binary_id)
      timestamps()
    end

    create index(:landing_features, [:landing_id])

    create table(:landing_faqs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question, :string
      add :answer, :text
      add :landing_id, references(:landings, on_delete: :delete_all, type: :binary_id)
      timestamps()
    end

    create index(:landing_faqs, [:landing_id])
  end
end
