defmodule BooksAdmin.PaginationComponent do
  use BooksAdmin, :component

  defp current_page(%_{page_number: page}, page), do: ["aria-current": "page"]
  defp current_page(_page, _i), do: []

  defp get_numbers(n, _total) when n in 1..3, do: 2..4
  defp get_numbers(n, total) when n >= total - 2, do: (total - 3)..(total - 1)
  defp get_numbers(n, _total), do: (n - 1)..(n + 1)

  defp get_class(%_{page_number: page}, page), do: "pagination-link is-current"
  defp get_class(_page, _i), do: "pagination-link"

  attr(:page, :any, required: true)
  attr(:url, :any, required: true)
  attr(:prev_page_text, :string, default: gettext("Previous"))
  attr(:next_page_text, :string, default: gettext("Next"))

  def paginate(assigns) do
    ~H"""
    <nav class="pagination is-centered" role="navigation" aria-label="pagination">
      <%= if @page.page_number == 1 do %>
      <a class="pagination-previous is-disabled"><%= @prev_page_text %></a>
      <% else %>
      <a class="pagination-previous" href={@url.(@page.page_number - 1)}><%= @prev_page_text %></a>
      <% end %>
      <%= if @page.page_number == @page.total_pages do %>
      <a class="pagination-next is-disabled"><%= @next_page_text %></a>
      <% else %>
      <a class="pagination-next" href={@url.(@page.page_number + 1)}><%= @next_page_text %></a>
      <% end %>
      <ul class="pagination-list">
        <%= if @page.total_pages in 1..5 do %>
          <%= for i <- 1..@page.total_pages do %>
          <li><a class={get_class(@page, i)} href={@url.(i)} aria-label={gettext("Goto page %{num}", num: i)} {current_page(@page, i)}><%= i %></a></li>
          <% end %>
        <% else %>
          <li><a class={get_class(@page, 1)} href={@url.(1)} aria-label={gettext("Goto page %{num}", num: 1)} {current_page(@page, 1)}>1</a></li>
          <%= if @page.page_number > 3 do %>
          <li><span class="pagination-ellipsis">&hellip;</span></li>
          <% end %>
          <%= for i <- get_numbers(@page.page_number, @page.total_pages) do %>
          <li><a class={get_class(@page, i)} href={@url.(i)} aria-label={gettext("Goto page %{num}", num: i)} {current_page(@page, i)}><%= i %></a></li>
          <% end %>
          <%= if @page.page_number < @page.total_pages - 2 do %>
          <li><span class="pagination-ellipsis">&hellip;</span></li>
          <% end %>
          <% i = @page.total_pages %>
          <li><a class={get_class(@page, i)} href={@url.(i)} aria-label={gettext("Goto page %{num}", num: i)} {current_page(@page, i)}><%= i %></a></li>
        <% end %>
      </ul>
    </nav>
    """
  end
end
