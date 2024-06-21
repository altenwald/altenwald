defmodule Books.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Books.Repo

  alias Books.Catalog
  alias Books.Posts.{Category, Comment, CommentNotifier, Post, Tag}

  @doc """
  Returns the list of post_categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories(locale \\ nil)

  def list_categories(nil) do
    from(c in Category, order_by: c.name)
    |> Repo.all()
  end

  def list_categories(locale) do
    from(
      c in Category,
      select: %{
        id: c.id,
        color: c.color,
        name: c.name[^locale]
      },
      order_by: :name
    )
    |> Repo.all()
  end

  def search_category(name) do
    from(c in Category, where: c.name["es"] == ^name or c.name["en"] == ^name, limit: 1)
    |> Repo.one()
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Post category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a post_category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post_category.

  ## Examples

      iex> update_post_category(post_category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_post_category(post_category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = post_category, attrs) do
    post_category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post_category.

  ## Examples

      iex> delete_post_category(post_category)
      {:ok, %Category{}}

      iex> delete_post_category(post_category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = post_category) do
    Repo.delete(post_category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post_category changes.

  ## Examples

      iex> change_post_category(post_category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = post_category, attrs \\ %{}) do
    Category.changeset(post_category, attrs)
  end

  @doc """
  Returns the list of post_tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  def list_tags do
    from(t in Tag, order_by: t.name)
    |> Repo.all()
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  def get_tag_by_name(name), do: Repo.get_by(Tag, name: name)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(lang) do
    from(p in Post,
      left_join: t in assoc(p, :tags),
      select: %Post{p | tags_text: fragment("string_agg(?, ',')", t.name)},
      group_by: p.id,
      where: p.lang == ^lang,
      order_by: [desc: p.inserted_at],
      preload: [:category, :books, :tags, :author, :comments]
    )
    |> Repo.all()
  end

  def list_posts_until(lang, datetime, params) do
    from(p in Post,
      left_join: t in assoc(p, :tags),
      select: %Post{p | tags_text: fragment("string_agg(?, ',')", t.name)},
      group_by: p.id,
      where: p.lang == ^lang and p.inserted_at <= ^datetime,
      order_by: [desc: p.inserted_at],
      preload: [:category, :books, :tags, :author, :comments]
    )
    |> Repo.all()
    |> Repo.paginate(params)
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id) do
    from(p in Post,
      left_join: t in assoc(p, :tags),
      select: %Post{p | tags_text: fragment("string_agg(?, ',')", t.name)},
      group_by: p.id,
      where: p.id == ^id,
      preload: [:category, :author, :books, :tags, comments: [:user]]
    )
    |> Repo.one!()
  end

  def get_full_title(post) when post.subtitle not in ["", nil] do
    "#{post.title}: #{post.subtitle}"
  end

  def get_full_title(post), do: post.title

  def get_post_by_slug(slug) do
    from(p in Post,
      left_join: t in assoc(p, :tags),
      select: %Post{p | tags_text: fragment("string_agg(?, ',')", t.name)},
      group_by: p.id,
      where: p.slug == ^slug,
      preload: [:category, :books, :tags, author: [:user], comments: [:user]]
    )
    |> Repo.one()
  end

  def get_author_by_post_id(post_id) do
    from(
      p in Books.Posts.Post,
      join: a in assoc(p, :author),
      where: p.id == ^post_id,
      select: a,
      group_by: a.id
    )
    |> Repo.one()
  end

  def get_users_by_comments_from_post_id(post_id) do
    from(
      c in Books.Posts.Comment,
      join: u in assoc(c, :user),
      where: c.post_id == ^post_id,
      select: u,
      group_by: u.id
    )
    |> Repo.all()
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    books_ids = get_books_by_ids(attrs["books"])

    attrs =
      Map.merge(attrs, %{
        "tags" => get_or_create_tags_by_name(attrs["tags_text"]) || attrs["tags"],
        "books" => books_ids,
        "private" => not Enum.empty?(books_ids),
        "slug" => get_slug(String.trim(attrs["slug"] || ""), attrs),
        "excerpt" => get_excerpt(String.trim(attrs["excerpt"] || ""), attrs["content"] || "")
      })

    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, post} ->
        post =
          post
          |> Repo.preload(~w[ category author tags books comments ]a)
          |> populate_tags_text()

        {:ok, post}

      {:error, _} = error ->
        error
    end
  end

  defp populate_tags_text(post) do
    post.tags
    |> Enum.map_join(",", & &1.name)
    |> then(&Map.put(post, :tags_text, &1))
  end

  defp get_slug("", attrs), do: slugify_post(attrs)
  defp get_slug(slug, _attrs), do: slug

  defp get_excerpt("", content) do
    case String.split(content, ~r/\n<!--\s*more\s*-->\s*\n/, parts: 2) do
      [excerpt, _] -> String.trim(excerpt)
      [_] -> hd(String.split(content, "\n", parts: 2))
    end
  end

  defp get_excerpt(excerpt, content) do
    case String.split(content, ~r/\n<!--\s*more\s*-->\s*\n/, parts: 2) do
      [new_excerpt, _] -> String.trim(new_excerpt)
      [_] -> excerpt
    end
  end

  defp slugify_post(%{"title" => title, "subtitle" => subtitle})
       when is_binary(title) and is_binary(subtitle) and subtitle != "" do
    Enum.join([String.trim(title), String.trim(subtitle)], " ")
    |> slugify_text()
  end

  defp slugify_post(%{"title" => title}) when is_binary(title) and title != "" do
    slugify_text(title)
  end

  defp slugify_post(_attrs), do: nil

  defp slugify_text(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/(\s|-)+/, "-")
  end

  defp get_or_create_tags_by_name(nil), do: nil

  defp get_or_create_tags_by_name(tags) do
    for tagname <- String.split(tags, ","), String.trim(tagname) != "" do
      tagname = String.trim(tagname)

      if tag = get_tag_by_name(tagname) do
        tag
      else
        {:ok, tag} = create_tag(%{"name" => tagname})
        tag
      end
    end
  end

  defp get_books_by_ids(nil), do: []

  defp get_books_by_ids(book_ids) do
    Enum.map(book_ids, &Catalog.get_book/1)
  end

  def new_post do
    Repo.preload(%Post{}, ~w[ category author tags books ]a)
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    books_ids = get_books_by_ids(attrs["books"])

    attrs =
      Map.merge(attrs, %{
        "tags" => get_or_create_tags_by_name(attrs["tags_text"]) || attrs["tags"],
        "books" => books_ids,
        "private" => not Enum.empty?(books_ids),
        "slug" => get_slug(String.trim(attrs["slug"] || ""), attrs),
        "excerpt" => get_excerpt(String.trim(attrs["excerpt"] || ""), attrs["content"] || "")
      })

    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def new_comment(attrs \\ %{}) do
    struct(Comment, attrs)
  end

  @doc """
  Returns the list of post_comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  defdelegate deliver_new_comment(user, post, url, locale), to: CommentNotifier

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end
end
