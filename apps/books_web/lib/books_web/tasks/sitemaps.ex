defmodule Mix.Tasks.BooksWeb.Sitemaps do
  use Mix.Task

  alias BooksWeb.Schedulers.Sitemaps

  @shortdoc "Generate sitemaps.xml"
  @impl Mix.Task
  def run(_) do
    [:sitemap, :ecto, :postgrex]
    |> Enum.each(&({:ok, _} = Application.ensure_all_started(&1)))

    Books.Repo.start_link()
    BooksWeb.Endpoint.start_link()
    Sitemaps.generate()
  end
end
