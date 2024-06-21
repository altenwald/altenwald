defmodule Books.BalancesFixtures do
  def income_fixture(attrs \\ %{}) do
    {:ok, income} =
      attrs
      |> Enum.into(%{
        month: 10,
        year: 2021,
        amount: Money.new(10),
        items: 1,
        book_id: unless(attrs[:book_id], do: Books.CatalogFixtures.book_fixture())
      })
      |> Books.Balances.create_income()

    income
  end

  def outcome_fixture(attrs \\ %{}) do
    {:ok, outcome} =
      attrs
      |> Enum.into(%{
        month: 10,
        year: 2021,
        amount: Money.new(10),
        items: 1,
        target: "paypal"
      })
      |> Books.Balances.create_outcome()

    outcome
  end
end
