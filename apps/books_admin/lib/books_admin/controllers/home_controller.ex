defmodule BooksAdmin.HomeController do
  use BooksAdmin, :controller

  alias Books.Balances

  @enabled_sources ["Altenwald", "Amazon Kindle", "Google Play", "PodiPrint"]

  def index(conn, _params) do
    %{year: current_year, month: current_month} = DateTime.utc_now()

    %{year: last_year, month: last_month} =
      DateTime.utc_now()
      |> Timex.shift(months: -1)

    render(conn, "index.html",
      last_month_income: Balances.current_income_by_source(last_year, last_month),
      current_month_income: Balances.current_income_by_source(current_year, current_month),
      enabled_sources: @enabled_sources,
      income_per_year: Balances.brief_balance(),
      income_by_book_per_year: Balances.brief_income_by_book_per_year(),
      income_chart_by_book_per_month: Balances.brief_balance_by_year_and_month()
    )
  end
end
