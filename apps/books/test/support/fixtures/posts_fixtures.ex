defmodule Books.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Books.Posts` context.
  """

  @doc """
  Generate a post_category.
  """
  def post_category_fixture(attrs \\ %{}) do
    {:ok, post_category} =
      attrs
      |> Enum.into(%{
        "color" => "some color",
        "name" => %{"en" => "some name"}
      })
      |> Books.Posts.create_category()

    post_category
  end

  @doc """
  Generate a tag.
  """
  def tag_fixture(attrs \\ %{}) do
    {:ok, tag} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Books.Posts.create_tag()

    tag
  end

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    category =
      if category = Books.Posts.search_category("noticias") do
        category
      else
        post_category_fixture(%{name: %{"es" => "noticias", "en" => "news"}})
      end

    tags =
      if tag = Books.Posts.get_tag_by_name("erlang") do
        [tag]
      else
        [tag_fixture(%{name: "erlang"})]
      end

    author =
      if author = Books.Catalog.search_author("Manuel") do
        author
      else
        Books.CatalogFixtures.author_fixture()
      end

    {:ok, post} =
      attrs
      |> Enum.into(%{
        "author_id" => author.id,
        "background_image" => "some background_image",
        "content" => "some content",
        "excerpt" => "some excerpt",
        "featured_image" => "some featured_image",
        "slug" => "some slug",
        "subtitle" => "some subtitle",
        "title" => "some title",
        "category_id" => category.id,
        "tags" => tags
      })
      |> Books.Posts.create_post()
      |> case do
        {:ok, post} -> {:ok, Books.Repo.preload(post, :comments)}
        {:error, _} = error -> error
      end

    post
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    {:ok, comment} =
      attrs
      |> Enum.into(%{
        content: "some content"
      })
      |> Books.Posts.create_comment()

    comment
  end
end
