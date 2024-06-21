defmodule Books.Landings do
  import Ecto.Query, only: [from: 2]

  alias Books.Catalog.Book
  alias Books.Landings.Landing
  alias Books.Repo

  @spec get_by_slug(String.t()) :: nil | Landing.t()
  def get_by_slug(slug) do
    from(
      l in Landing,
      left_join: b in assoc(l, :book),
      where: (b.slug == ^slug or ^slug in l.slugs) and l.enable,
      preload: [
        :faqs,
        :features,
        book: ^Book.preload(),
        bundle: [:contents, formats: [book: ^Book.preload()]]
      ]
    )
    |> Repo.one()
  end

  def list_landings do
    Repo.all(Landing)
  end

  def update_landing(%Landing{} = landing, attrs) do
    landing
    |> Landing.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, landing} ->
        {:ok, Repo.preload(landing, [:book, :bundle])}

      {:error, _} = error ->
        error
    end
  end

  def delete_landing(%Landing{} = landing) do
    Repo.delete(landing)
  end

  def change_landing(%Landing{} = landing, attrs \\ %{}) do
    Landing.changeset(landing, attrs)
  end

  def get_landing!(id) do
    Landing
    |> Repo.get!(id)
    |> Repo.preload([:book, :bundle])
  end

  def create_landing(attrs) do
    %Landing{}
    |> Landing.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, landing} ->
        {:ok, Repo.preload(landing, [:book, :bundle])}

      {:error, _} = error ->
        error
    end
  end

  def new_landing do
    %Landing{}
    |> Repo.preload([:book, :bundle])
  end
end
