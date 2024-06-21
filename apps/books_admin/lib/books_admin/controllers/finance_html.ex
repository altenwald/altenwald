defmodule BooksAdmin.FinanceHTML do
  use BooksAdmin, :html

  import BooksAdmin.PaginationComponent

  defp get_name(%_{type: :outcome, name: name}), do: name
  defp get_name(%_{type: :income, book_id: nil, name: name}), do: name

  defp get_name(%_{type: :income} = balance) do
    "[#{balance.name}] #{balance.book.title}"
  end

  defp get_date(%_{year: year, month: month}) do
    "#{String.pad_leading(to_string(month), 2, "0")}/#{year}"
  end

  embed_templates("finance_html/*")
end
