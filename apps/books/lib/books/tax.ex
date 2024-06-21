defmodule Books.Tax do
  @book_tax 4
  @shipping_tax 21

  def get_amount(price, _country_code) do
    # obtain @book_tax keeping in mind that "price" percentage is @book_tax + 100
    Money.multiply(price, @book_tax / (@book_tax + 100))
  end

  def get_shipping_amount(price, _country_code) do
    # obtain @book_tax keeping in mind that "price" percentage is @book_tax + 100
    Money.multiply(price, @shipping_tax / (@shipping_tax + 100))
  end

  def get_tax(_), do: @book_tax
  def get_shipping_tax(_), do: @shipping_tax
end
