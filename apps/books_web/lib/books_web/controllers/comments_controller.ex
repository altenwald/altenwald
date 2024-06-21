defmodule BooksWeb.CommentsController do
  use BooksWeb, :controller
  require Logger
  alias Books.Posts
  alias BooksWeb.PostsHTML

  def create(conn, %{"slug" => slug, "comment" => comment_params}) do
    user = conn.assigns.current_user

    if post = Posts.get_post_by_slug(slug) do
      comment_params
      |> Map.put("post_id", post.id)
      |> Map.put("user_id", user.id)
      |> Posts.create_comment()
      |> case do
        {:ok, comment} ->
          section = "#comment-#{comment.id}"
          url = PostsHTML.post_url(conn, post) <> section

          [post.author.user | Enum.map(post.comments, & &1.user)]
          |> Enum.uniq()
          |> Enum.reject(&(&1.id == user.id))
          |> Enum.each(&Posts.deliver_new_comment(&1, post, url, conn.assigns.locale))

          conn
          |> put_flash(:info, gettext("comment created successfully"))
          |> redirect(to: PostsHTML.post_path(conn, post) <> section)

        {:error, changeset} ->
          Logger.error("cannot create comment: #{inspect(changeset.errors)}")

          conn
          |> put_flash(:error, gettext("cannot create comment"))
          |> redirect(to: PostsHTML.post_path(conn, post))
      end
    else
      raise BooksWeb.ErrorNotFound, message: gettext("post not found")
    end
  end
end
