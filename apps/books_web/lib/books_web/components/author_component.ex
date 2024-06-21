defmodule BooksWeb.AuthorComponent do
  use BooksWeb, :component

  def author_box(assigns) do
    ~H"""
    <div class="card-content">
      <div class="media">
        <div class="media-left is-hidden-touch">
          <figure class="image is-48x48">
            <img
              class="is-rounded"
              src={Routes.static_path(@conn, "/images/authors/#{@author.id}.png")}
              alt={@author.short_name}
            />
          </figure>
        </div>
        <div class="media-content author-data">
          <figure class="image is-48x48 is-hidden-desktop is-inline-block">
            <img
              class="is-rounded"
              src={Routes.static_path(@conn, "/images/authors/#{@author.id}.png")}
              alt={@author.short_name}
            />
          </figure>
          <p class="title is-4"><%= @author.full_name %></p>
          <p class="subtitle is-6">
            <%= link(@author.title[@locale],
              to: @author.urls["personal"],
              rel: "noopener",
              target: "_blank"
            ) %>
          </p>
        </div>
      </div>
      <div class="content"></div>
    </div>
    """
  end
end
