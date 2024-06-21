defmodule Books.Balances do
  import Ecto.Query, warn: false

  require Logger

  alias Books.Balances.{Balance, Income, Outcome}
  alias Books.Catalog
  alias Books.Catalog.Book
  alias Books.Repo

  def create_income(attrs \\ %{}) do
    %Income{}
    |> Income.changeset(attrs)
    |> Repo.insert()
  end

  def create_outcome(attrs \\ %{}) do
    %Outcome{}
    |> Outcome.changeset(attrs)
    |> Repo.insert()
  end

  def add_income(amount, items, month, year, book_id \\ nil, source \\ nil)

  def add_income(amount, items, month, year, book_id, nil) do
    add_income(amount, items, month, year, book_id, Income.default_source())
  end

  def add_income(amount, items, month, year, book_id, source) do
    income =
      get_income(month, year, book_id, source)
      |> new_income_if_nil(month, year, book_id, source)

    amount = Money.add(amount, income.amount)

    if book_id do
      Logger.info("add to #{source} for #{book_id} #{year}-#{month} -> #{amount}")
    else
      Logger.info("add to #{source} #{year}-#{month} -> #{amount}")
    end

    Income.changeset(income, %{amount: amount, items: income.items + items})
    |> Repo.update!()
  end

  def update_income(%Income{} = income, attrs) do
    income
    |> Income.changeset(attrs)
    |> Repo.update()
  end

  def update_outcome(%Outcome{} = outcome, attrs) do
    outcome
    |> Outcome.changeset(attrs)
    |> Repo.update()
  end

  def new_income do
    date = Date.utc_today()
    %Income{year: date.year, month: date.month, items: 1}
  end

  def new_outcome do
    date = Date.utc_today()
    %Outcome{year: date.year, month: date.month, items: 1}
  end

  def add_outcome(amount, items, month, year, target) do
    outcome =
      get_outcome(month, year, target)
      |> new_outcome_if_nil(month, year, target)

    amount = Money.add(amount, outcome.amount)

    Logger.info("add outcome to #{target} #{year}/#{month} -> #{inspect(amount)}")

    Outcome.changeset(outcome, %{amount: amount, items: outcome.items + items})
    |> Repo.update!()
  end

  def get_income(month, year, nil, source) do
    from(i in Income,
      where: i.month == ^month,
      where: i.year == ^year,
      where: i.source == ^source,
      where: is_nil(i.book_id),
      limit: 1
    )
    |> Repo.one()
  end

  def get_income(month, year, book_id, source) do
    Repo.get_by(Income, month: month, year: year, source: source, book_id: book_id)
  end

  def get_income(income_id) do
    Repo.get(Income, income_id)
  end

  def change_income(income, attrs \\ %{}) do
    Income.changeset(income, attrs)
  end

  def delete_income(%Income{} = income) do
    income
    |> Income.changeset(%{})
    |> Repo.delete()
  end

  defp new_income_if_nil(nil, month, year, book_id, source) do
    income = %Income{month: month, year: year, book_id: book_id, source: source}

    Income.changeset(income, %{})
    |> Repo.insert!()
  end

  defp new_income_if_nil(income, _month, _year, _book_id, _source), do: income

  def get_outcome(month, year, target) do
    Repo.get_by(Outcome, month: month, year: year, target: target)
  end

  def get_outcome(outcome_id) do
    Repo.get(Outcome, outcome_id)
  end

  def change_outcome(outcome, attrs \\ %{}) do
    Outcome.changeset(outcome, attrs)
  end

  def delete_outcome(%Outcome{} = outcome) do
    outcome
    |> Outcome.changeset(%{})
    |> Repo.delete()
  end

  defp new_outcome_if_nil(nil, month, year, target) do
    outcome = %Outcome{month: month, year: year, target: target}

    Outcome.changeset(outcome, %{})
    |> Repo.insert!()
  end

  defp new_outcome_if_nil(outcome, _month, _year, _target), do: outcome

  def brief_balance do
    from(
      b in Balance,
      select: [
        b.year,
        sum(b.amount),
        type(sum(b.amount) / 12, Money.Ecto.Type),
        sum(b.items)
      ],
      group_by: [b.year],
      order_by: [desc: b.year]
    )
    |> Repo.all()
  end

  def brief_income_by_book_per_year do
    from(
      i in Income,
      join: b in assoc(i, :book),
      select: [
        i.year,
        b.title,
        sum(i.amount)
      ],
      group_by: [i.year, b.title],
      order_by: [asc: i.year, asc: b.title]
    )
    |> Repo.all()
  end

  def brief_balance_by_year_per_month(year) do
    balances =
      from(b in Balance,
        select: %{
          year: b.year,
          month: b.month,
          items: count(b.items),
          amount: sum(b.amount)
        },
        group_by: [b.year, b.month],
        order_by: [b.month]
      )

    from(b in subquery(balances),
      where: b.year == ^year,
      select: %{
        year: b.year,
        month: b.month,
        items: b.items,
        amount: b.amount,
        balance:
          b.amount
          |> type(:decimal)
          |> sum()
          |> over(order_by: b.month)
          |> type(Money.Ecto.Type)
      }
    )
    |> Repo.all()
  end

  def brief_balance_by_year_and_month do
    from(
      b in Balance,
      select: [
        b.year,
        b.month,
        sum(b.amount)
      ],
      group_by: [b.year, b.month],
      order_by: [asc: b.year, asc: b.month]
    )
    |> Repo.all()
  end

  def brief_income_by_source do
    from(
      i in Income,
      select: [
        i.source,
        sum(i.amount),
        sum(i.items)
      ],
      group_by: i.source,
      order_by: [desc: fragment("2")]
    )
    |> Repo.all()
  end

  def brief_outcome_by_source do
    from(
      o in Outcome,
      select: {o.source, sum(o.amount)},
      group_by: o.source,
      order_by: [desc: fragment("2")]
    )
    |> Repo.all()
  end

  def current_income_by_source(year, month) do
    sources = from(i in Income, select: i.source, group_by: [i.source])

    from(
      s in subquery(sources),
      left_join: i in Income,
      on: s.source == i.source and i.year == ^year and i.month == ^month,
      select: {s.source, type(sum(coalesce(i.amount, 0)), Money.Ecto.Type)},
      group_by: [s.source]
    )
    |> Repo.all()
    |> Map.new()
  end

  def list_books do
    Book
    |> Books.Repo.all()
    |> Enum.map(&{Catalog.get_full_book_title(&1), &1.id})
    |> Enum.sort()
  end

  defp maybe_filter_balances(query, _field, nil), do: query
  defp maybe_filter_balances(query, _field, ""), do: query

  defp maybe_filter_balances(query, field, value) do
    where(query, ^[{field, value}])
  end

  def list_balances(params) do
    from(b in Balance,
      order_by: [desc: b.year, desc: b.month, asc: b.name, asc: b.book_id],
      preload: [:book]
    )
    |> maybe_filter_balances(:year, params["year"])
    |> maybe_filter_balances(:month, params["month"])
    |> maybe_filter_balances(:name, params["name"])
    |> maybe_filter_balances(:type, params["type"])
    |> Repo.paginate(params)
  end
end
