defmodule BooksWeb.PostsController do
  use BooksWeb, :controller
  require Logger
  alias Books.{Accounts, Catalog, Posts}
  alias BooksWeb.ImageHelpers

  @recent_posts 1
  @first_page_posts @recent_posts * 4

  def index(conn, %{"page" => page} = params) when page != "1" do
    locale = conn.assigns.locale
    now = NaiveDateTime.utc_now()
    params = Map.put(params, "page_size", @recent_posts + @first_page_posts)

    render(
      conn,
      "index.html",
      default_opts(conn,
        title: gettext("Posts"),
        posts: Posts.list_posts_until(locale, now, params),
        recent_posts: 0
      )
    )
  end

  def index(conn, _params) do
    locale = conn.assigns.locale
    now = NaiveDateTime.utc_now()

    params = %{
      page: 1,
      page_size: @recent_posts + @first_page_posts
    }

    render(
      conn,
      "index.html",
      default_opts(conn,
        title: gettext("Posts"),
        posts: Posts.list_posts_until(locale, now, params),
        recent_posts: @recent_posts
      )
    )
  end

  def new(conn, _params) do
    with user = %_{} <- conn.assigns.current_user,
         _author = %{} <- Catalog.get_author_from_user(user) do
      post = Posts.new_post()

      default_params = %{
        "inserted_at" => NaiveDateTime.utc_now(),
        "lang" => conn.assigns.locale
      }

      render(
        conn,
        "new.html",
        default_opts(conn,
          disable_analytics: true,
          title: gettext("New post"),
          post: post,
          changeset: Posts.change_post(post, default_params),
          languages: list_languages(),
          categories: list_categories(),
          book_list: list_books(),
          tags: list_tags(),
          featured: list_featured(),
          backgrounds: list_backgrounds()
        )
      )
    else
      nil ->
        redirect(conn, to: Routes.posts_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => post_id}) do
    with user = %_{} <- conn.assigns.current_user,
         _author = %{} <- Catalog.get_author_from_user(user) do
      post = Posts.get_post!(post_id)

      render(
        conn,
        "edit.html",
        default_opts(conn,
          disable_analytics: true,
          title: gettext("Edit post"),
          post: post,
          changeset: Posts.change_post(post),
          languages: list_languages(),
          categories: list_categories(),
          book_list: list_books(),
          tags: list_tags(),
          featured: list_featured(),
          backgrounds: list_backgrounds()
        )
      )
    else
      nil ->
        redirect(conn, to: Routes.posts_path(conn, :index))
    end
  end

  def create(conn, %{"post" => params}) do
    with user = %_{} <- conn.assigns.current_user,
         author = %{} <- Catalog.get_author_from_user(user),
         params = Map.put(params, "author_id", author.id),
         {:ok, post} <- Posts.create_post(params) do
      redirect(conn,
        to:
          Routes.posts_path(
            conn,
            :show,
            post.inserted_at.year,
            post.inserted_at.month,
            post.inserted_at.day,
            post.slug
          )
      )
    else
      nil ->
        redirect(conn, to: Routes.posts_path(conn, :index))

      {:error, changeset} ->
        Logger.error("cannot save #{inspect(changeset)}")

        render(
          conn,
          "new.html",
          default_opts(conn,
            disable_analytics: true,
            title: gettext("New post"),
            post: Posts.new_post(),
            changeset: changeset,
            languages: list_languages(),
            categories: list_categories(),
            tags: list_tags(),
            book_list: list_books(),
            featured: list_featured(),
            backgrounds: list_backgrounds()
          )
        )
    end
  end

  def update(conn, %{"id" => post_id, "post" => params}) do
    with user = %_{} <- conn.assigns.current_user,
         %{id: author_id} <- Catalog.get_author_from_user(user),
         post = %{author_id: ^author_id} <- Posts.get_post!(post_id),
         params = Map.delete(params, "author_id"),
         {:ok, post} <- Posts.update_post(post, params) do
      redirect(conn,
        to:
          Routes.posts_path(
            conn,
            :show,
            post.inserted_at.year,
            post.inserted_at.month,
            post.inserted_at.day,
            post.slug
          )
      )
    else
      nil ->
        redirect(conn, to: Routes.posts_path(conn, :index))

      %{} ->
        redirect(conn, to: Routes.posts_path(conn, :index))

      {:error, changeset} ->
        Logger.error("cannot save #{inspect(changeset)}")

        render(
          conn,
          "new.html",
          default_opts(conn,
            disable_analytics: true,
            title: gettext("New post"),
            post: Posts.new_post(),
            changeset: changeset,
            languages: list_languages(),
            categories: list_categories(),
            tags: list_tags(),
            book_list: list_books(),
            featured: list_featured(),
            backgrounds: list_backgrounds()
          )
        )
    end
  end

  defp list_featured do
    ImageHelpers.get_post_images()
    |> Enum.map(&Path.basename/1)
    |> Enum.sort()
  end

  defp list_backgrounds do
    ImageHelpers.get_background_images()
    |> Enum.map(&Path.basename/1)
    |> Enum.sort()
  end

  defp list_languages do
    [
      {gettext("English"), "en"},
      {gettext("Spanish"), "es"}
    ]
  end

  defp list_categories do
    locale = BooksWeb.Gettext.get_locale()

    for category <- Posts.list_categories(locale) do
      {category.name, category.id}
    end
  end

  defp list_tags do
    Posts.list_tags()
    |> Enum.map_join(",", & &1.name)
  end

  defp list_books do
    for book <- Catalog.list_all_books_simple() do
      {Catalog.get_full_book_title(book), book.id}
    end
  end

  defp nested_comments(comments, root \\ nil) do
    {root_comments, rest_comments} = Enum.split_with(comments, &(&1.parent_id == root))

    for comment <- root_comments do
      Map.put(comment, :comments, nested_comments(rest_comments, comment.id))
    end
  end

  def show(conn, %{"slug" => slug}) do
    current_user = conn.assigns[:current_user]
    post = Posts.get_post_by_slug(slug)

    if is_nil(post) or post.lang != conn.assigns[:locale] do
      raise BooksWeb.ErrorNotFound, message: gettext("post not found")
    end

    render(
      conn,
      "show.html",
      default_opts(conn,
        post: post,
        permitted?: permitted?(post, current_user),
        comments: nested_comments(post.comments),
        comment:
          if current_user do
            Posts.new_comment(post_id: post.id, author_id: current_user)
          end,
        changeset: Posts.change_comment(Posts.new_comment()),
        users:
          Posts.get_users_by_comments_from_post_id(post.id)
          |> Enum.group_by(& &1.id),
        title: post.title
      )
    )
  end

  defp permitted?(%_{private: false}, _user), do: true

  defp permitted?(_post, nil), do: false

  defp permitted?(%_{books: []}, _user), do: false

  defp permitted?(%_{books: books}, user) do
    bookshelf_ids =
      user.id
      |> Accounts.list_bookshelf_ids_by_user_id()
      |> MapSet.new()

    books_ids =
      books
      |> Enum.map(& &1.id)
      |> MapSet.new()

    MapSet.new() != MapSet.intersection(bookshelf_ids, books_ids)
  end
end
