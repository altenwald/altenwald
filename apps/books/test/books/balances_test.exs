defmodule Books.BalancesTest do
  use Books.DataCase

  alias Books.Balances

  describe "income" do
    import Books.CatalogFixtures
    import Books.BalancesFixtures

    test "add income" do
      total = Money.new(10_00)
      quantity = 1
      month = 10
      year = 2021
      category = category_fixture()
      book = book_fixture(%{slug: "book-income-i", category_id: category.id})

      real_total = total

      assert %Balances.Income{month: ^month, year: ^year, amount: ^real_total, items: 1} =
               Balances.add_income(total, quantity, month, year, book.id)

      another_book = book_fixture(%{slug: "book-income-ii", category_id: category.id})

      assert %Balances.Income{month: ^month, year: ^year, amount: ^real_total, items: 1} =
               Balances.add_income(total, quantity, month, year, another_book.id)

      real_total = Money.add(total, total)

      assert %Balances.Income{month: ^month, year: ^year, amount: ^real_total, items: 2} =
               Balances.add_income(total, quantity, month, year, book.id)
    end

    test "check brief" do
      category = category_fixture()
      book = book_fixture(%{slug: "book-brief-i", category_id: category.id})

      income_fixture(%{
        month: 10,
        year: 2021,
        items: 10,
        amount: Money.new(28_85),
        source: "Amazon KDP",
        book_id: book.id
      })

      income_fixture(%{
        month: 10,
        year: 2021,
        items: 8,
        amount: Money.new(12_05),
        source: "Kobo",
        book_id: book.id
      })

      income_fixture(%{
        month: 11,
        year: 2021,
        items: 12,
        amount: Money.new(32_75),
        source: "Amazon KDP",
        book_id: book.id
      })

      income_fixture(%{
        month: 11,
        year: 2021,
        items: 1,
        amount: Money.new(2_15),
        source: "Kobo",
        book_id: book.id
      })

      total_income = Money.new(75_80)
      monthly_avg = Money.new(div(75_80, 12))
      total_items = 31
      assert [[2021, total_income, monthly_avg, total_items]] == Balances.brief_balance()
    end
  end

  describe "outcome" do
    import Books.BalancesFixtures

    test "add outcome" do
      fee = Money.new(2_60)
      quantity = 1
      month = 10
      year = 2021
      target = "paypal"

      real_fee = fee

      assert %Balances.Outcome{month: ^month, year: ^year, amount: ^real_fee, items: 1} =
               Balances.add_outcome(fee, quantity, month, year, target)

      another_target = "stripe"

      assert %Balances.Outcome{month: ^month, year: ^year, amount: ^real_fee, items: 1} =
               Balances.add_outcome(fee, quantity, month, year, another_target)

      real_fee = Money.add(fee, fee)

      assert %Balances.Outcome{month: ^month, year: ^year, amount: ^real_fee, items: 2} =
               Balances.add_outcome(fee, quantity, month, year, target)
    end
  end
end
