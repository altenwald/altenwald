defmodule BooksAdmin.HomeHTML do
  use BooksAdmin, :html

  def source_icon("Amazon Kindle"), do: "fab fa-amazon"
  def source_icon("Google Play"), do: "fab fa-google-play"
  def source_icon(_), do: "fas fa-book-open"

  defp income_chart_by_book_per_year(income) do
    current_year = Date.utc_today().year

    colors = %{
      # purple
      0 => "rgb(153, 102, 255)",
      # blue
      1 => "rgb(54, 162, 235)",
      # red
      2 => "rgb(255, 99, 132)",
      # green
      3 => "rgb(75, 192, 192)",
      # orange
      4 => "rgb(255, 159, 64)",
      # gray
      5 => "rgb(201, 203, 207)",
      # yellow
      6 => "rgb(255, 205, 86)"
    }

    years = Enum.to_list(2012..current_year)

    books =
      income
      |> Enum.map(fn [_year, title, _money] -> title end)
      |> Enum.sort()
      |> Enum.uniq()

    for {book, i} <- Enum.with_index(books) do
      book_income =
        for year <- years do
          to_str = fn
            [_, _, %Money{amount: amount}] -> to_string(amount / 100)
            nil -> "undefined"
          end

          income
          |> Enum.find(fn [y, b, _] -> year == y and book == b end)
          |> to_str.()
        end

      %{
        label: book,
        data: book_income,
        backgroundColor: colors[i]
      }
    end
  end

  def income_chart_by_book_per_month(income) do
    current_year = Date.utc_today().year
    years = Enum.to_list(2012..current_year)
    months = Enum.to_list(1..12)

    colors = %{
      # red
      0 => "#ff0000",
      # orange
      1 => "#ff8800",
      # yellow
      2 => "#ffff00",
      # chartreuse
      3 => "#80ff00",
      # green
      4 => "#00ff00",
      # spring green
      5 => "#00ff80",
      # cyan
      6 => "#00ffff",
      # dodger blue
      7 => "#0080ff",
      # blue
      8 => "#0000ff",
      # purple
      9 => "#8000ff",
      # violet
      10 => "#ff00ff",
      # magenta
      11 => "#ff0080"
    }

    for {month, i} <- Enum.with_index(months) do
      month_income =
        for year <- years do
          to_str = fn
            [_, _, %Money{amount: amount}] -> to_string(amount / 100)
            nil -> 0
          end

          income
          |> Enum.find(fn [y, m, _] -> year == y and month == m end)
          |> to_str.()
        end

      %{
        label: month,
        data: month_income,
        backgroundColor: colors[i]
      }
    end
  end

  embed_templates("home_html/*")
end
