defmodule BooksAdmin.FinanceController do
  use BooksAdmin, :controller
  require Logger
  alias Books.{Balances, Catalog}

  @starting_year 2012

  defp list_months do
    [
      {gettext("January"), 1},
      {gettext("February"), 2},
      {gettext("March"), 3},
      {gettext("April"), 4},
      {gettext("May"), 5},
      {gettext("June"), 6},
      {gettext("July"), 7},
      {gettext("August"), 8},
      {gettext("September"), 9},
      {gettext("October"), 10},
      {gettext("November"), 11},
      {gettext("December"), 12}
    ]
  end

  defp list_sources do
    [
      "Altenwald",
      "PodiPrint",
      "Amazon Kindle",
      "Bubok",
      "Google Play",
      "Kobo",
      "Lulu Press",
      "Sellfy"
    ]
  end

  defp list_books do
    for book <- Catalog.list_all_books_simple() do
      {Catalog.get_full_book_title(book), book.id}
    end
  end

  def index(conn, params) do
    render(
      conn,
      "index.html",
      [
        title: gettext("Balances"),
        page: Balances.list_balances(params)
      ]
      |> filters(params)
    )
  end

  defp filters(options, params) do
    [
      year: params["year"],
      month: params["month"],
      years: Enum.to_list(Date.utc_today().year..@starting_year),
      months: list_months()
    ] ++ options
  end

  defp options(balance, :income, changeset, return_to) do
    [
      title:
        case balance do
          %_{id: nil} -> gettext("New income")
          _ -> gettext("Update income")
        end,
      changeset: changeset,
      balance: balance,
      sources: list_sources(),
      books: list_books(),
      return_to: return_to
    ]
  end

  defp options(balance, :outcome, changeset, return_to) do
    [
      title:
        case balance do
          %_{id: nil} -> gettext("New outcome")
          _ -> gettext("Update outcome")
        end,
      changeset: changeset,
      balance: balance,
      books: list_books(),
      return_to: return_to
    ]
  end

  defp default_return_to(conn) do
    Routes.finance_path(conn, :index)
  end

  def edit_income(conn, %{"id" => income_id} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    income = Balances.get_income(income_id)

    render(
      conn,
      "edit_income.html",
      income
      |> options(:income, Balances.change_income(income), return_to)
      |> filters(params)
    )
  end

  def edit_outcome(conn, %{"id" => outcome_id} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    outcome = Balances.get_outcome(outcome_id)

    render(
      conn,
      "edit_outcome.html",
      outcome
      |> options(:outcome, Balances.change_outcome(outcome), return_to)
      |> filters(params)
    )
  end

  def new_income(conn, params) do
    return_to = params["return_to"] || default_return_to(conn)
    income = Balances.new_income()

    render(
      conn,
      "new_income.html",
      income
      |> options(:income, Balances.change_income(income), return_to)
      |> filters(params)
    )
  end

  def new_outcome(conn, params) do
    return_to = params["return_to"] || default_return_to(conn)
    outcome = Balances.new_outcome()

    render(
      conn,
      "new_outcome.html",
      outcome
      |> options(:outcome, Balances.change_outcome(outcome), return_to)
      |> filters(params)
    )
  end

  def delete(conn, %{"id" => income_id, "type" => "income"} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    income = Balances.get_income(income_id)

    case Balances.delete_income(income) do
      {:ok, _income} ->
        conn
        |> put_flash(:info, gettext("Income removed successfully!"))
        |> redirect(to: return_to)

      {:error, reason} ->
        Logger.error("cannot remove #{income_id}, reason: #{inspect(reason)}")

        conn
        |> put_flash(:error, gettext("Cannot remove income"))
        |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"id" => outcome_id, "type" => "outcome"} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    outcome = Balances.get_outcome(outcome_id)

    case Balances.delete_outcome(outcome) do
      {:ok, _outcome} ->
        conn
        |> put_flash(:info, gettext("Outcome removed successfully!"))
        |> redirect(to: return_to)

      {:error, reason} ->
        Logger.error("cannot remove #{outcome_id}, reason: #{inspect(reason)}")

        conn
        |> put_flash(:error, gettext("Cannot remove outcome"))
        |> redirect(to: return_to)
    end
  end

  def update(
        conn,
        %{"id" => income_id, "income" => %{"type" => "income"} = params} = global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn)
    income = Balances.get_income(income_id)

    case Balances.update_income(income, params) do
      {:ok, _income} ->
        conn
        |> put_flash(:info, gettext("Income modified successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot update income: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("edit_income.html", options(income, :income, changeset, return_to))
    end
  end

  def update(
        conn,
        %{"id" => outcome_id, "outcome" => %{"type" => "outcome"} = params} = global_params
      ) do
    return_to = global_params["return_to"] || default_return_to(conn)
    outcome = Balances.get_outcome(outcome_id)

    case Balances.update_outcome(outcome, params) do
      {:ok, _outcome} ->
        conn
        |> put_flash(:info, gettext("Outcome modified successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot update outcome: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("edit_outcome.html", options(outcome, :outcome, changeset, return_to))
    end
  end

  def create(conn, %{"income" => %{"type" => "income"} = params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)

    case Balances.create_income(params) do
      {:ok, _income} ->
        conn
        |> put_flash(:info, gettext("Income created successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot create income: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("new.html", options(Balances.new_income(), :income, changeset, return_to))
    end
  end

  def create(conn, %{"outcome" => %{"type" => "outcome"} = params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)

    case Balances.create_outcome(params) do
      {:ok, _outcome} ->
        conn
        |> put_flash(:info, gettext("Outcome created successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot create outcome: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("new.html", options(Balances.new_outcome(), :outcome, changeset, return_to))
    end
  end
end
