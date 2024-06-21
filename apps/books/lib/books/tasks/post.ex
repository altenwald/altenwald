defmodule Mix.Tasks.Books.Post do
  use Mix.Task

  @default_lang "es"

  @shortdoc "Load lambdapad post file"
  @impl Mix.Task
  def run([file]) do
    [:ecto, :postgrex]
    |> Enum.each(&({:ok, _} = Application.ensure_all_started(&1)))

    Books.Repo.start_link()

    content = File.read!(file)
    [header, post] = String.split(content, "\n\n", parts: 2)

    excerpt = get_excerpt(post)
    metadata = get_metadata(header)

    author = Books.Catalog.search_author(metadata["author"])
    category = Books.Posts.search_category(metadata["category"])
    lang = metadata["lang"] || @default_lang

    tags = get_tags(metadata["tags"])
    created = to_datetime(metadata["date"])
    updated = get_updated_at(metadata["updated"], created)
    books = get_books(metadata["books"])

    %{
      "slug" => metadata["id"],
      "title" => metadata["title"],
      "subtitle" => metadata["subtitle"],
      "author_id" => author.id,
      "featured_image" => metadata["featured"],
      "background_image" => metadata["background"],
      "category_id" => category.id,
      "inserted_at" => created,
      "updated_at" => updated,
      "content" => post,
      "excerpt" => excerpt,
      "lang" => lang,
      "tags" => tags,
      "private" => metadata["private"] == "true" or books != [],
      "books" => books
    }
    |> Books.Posts.create_post()
    |> case do
      {:ok, _post} -> {:ok, :created}
      {:error, changeset} -> changeset.errors
    end
  end

  defp get_excerpt(post) do
    case String.split(post, ~r/\n<!--\s*more\s*-->\s*\n/, parts: 2) do
      [excerpt, _] -> excerpt
      [_] -> hd(String.split(post, "\n", parts: 2))
    end
  end

  defp get_metadata(header) do
    header
    |> String.split("\n")
    |> Enum.map(fn line ->
      [key, value] = String.split(String.trim(line), ":", parts: 2)
      {String.trim(key), String.trim(value)}
    end)
    |> Map.new()
  end

  defp get_tags(tags) when is_binary(tags) do
    for tagname <- String.split(tags, ",") do
      tagname = String.trim(tagname)

      if tag = Books.Posts.get_tag_by_name(tagname) do
        tag
      else
        {:ok, tag} = Books.Posts.create_tag(%{"name" => tagname})
        tag
      end
    end
  end

  defp get_updated_at(nil, created_at), do: created_at
  defp get_updated_at(updated_at, _created_at), do: to_datetime(updated_at)

  defp to_datetime(date), do: "#{date}T00:00:00"

  defp get_books(books) do
    books
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&Books.Catalog.get_book_by_slug/1)
    |> Enum.reject(&is_nil/1)
  end
end
