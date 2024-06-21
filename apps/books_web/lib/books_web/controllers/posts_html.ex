defmodule BooksWeb.PostsHTML do
  use BooksWeb, :html
  import BooksWeb.MarkdownHelpers
  import BooksAdmin.PaginationComponent
  import BooksWeb.FormComponent
  import Books.Accounts, only: [user_role?: 2]
  import Books.Catalog, only: [get_full_book_title: 1]
  alias Books.Posts.Post

  defp background_image(_conn, %Post{background_image: nil}), do: ""

  defp background_image(conn, %Post{background_image: background_image}) do
    "background-image: url('" <>
      static_path(conn, "/images/backgrounds/#{background_image}") <> "')"
  end

  defp get_post_date(post) do
    year = to_string(post.inserted_at.year)

    month =
      post.inserted_at.month
      |> to_string()
      |> String.pad_leading(2, "0")

    day =
      post.inserted_at.day
      |> to_string()
      |> String.pad_leading(2, "0")

    {year, month, day}
  end

  def post_path(conn, post) do
    {year, month, day} = get_post_date(post)
    Routes.posts_path(conn, :show, year, month, day, post.slug)
  end

  def post_url(conn, post) do
    {year, month, day} = get_post_date(post)
    Routes.posts_url(conn, :show, year, month, day, post.slug)
  end

  defp get_date(post) do
    created_date = NaiveDateTime.to_date(post.inserted_at)
    to_string(created_date)
  end

  defp get_full_date(post) do
    created_date = NaiveDateTime.to_date(post.inserted_at)
    updated_date = NaiveDateTime.to_date(post.updated_at)

    if created_date == updated_date do
      to_string(created_date)
    else
      updated_at = gettext("updated at")
      "#{to_string(created_date)} (#{updated_at} #{to_string(updated_date)})"
    end
  end

  defp get_title(post) do
    if subtitle = post.subtitle do
      "#{post.title}: #{subtitle}"
    else
      post.title
    end
  end

  defp get_reading_min(post) do
    words_count =
      post.content
      |> String.replace(~r/@|#|\$|%|&|\^|:|_|!|,/u, " ")
      |> String.split()
      |> length()

    max(1, div(words_count, 200))
  end

  defp get_excerpt(post) do
    if excerpt = post.excerpt do
      excerpt
    else
      hd(String.split(post.content, "\n", parts: 2))
    end
  end

  defp user_name(%_{first_name: nil, last_name: nil}), do: gettext("Unknown user")
  defp user_name(%_{first_name: first_name, last_name: nil}), do: first_name
  defp user_name(%_{first_name: nil, last_name: last_name}), do: last_name

  defp user_name(%_{first_name: first_name, last_name: last_name}),
    do: "#{first_name} #{last_name}"

  defp comment(assigns) do
    assigns =
      assigns
      |> assign(:user, hd(assigns.users[assigns.comment.user_id]))
      |> assign(:comment_anchor, "comment-#{assigns.comment.id}")

    ~H"""
    <li>
      <a name={@comment_anchor}></a>
      <div class="message-data">
        <span class="message-data-name">
          <%= link to: "##{@comment_anchor}" do %>
            <i class="fa fa-circle you"></i> <%= user_name(@user) %>
          <% end %>
        </span>
      </div>
      <div class="message you-message"><%= @comment.content %></div>
    </li>
    """
  end

  embed_templates "posts_html/*"
end
