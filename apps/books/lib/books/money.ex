defmodule Books.Money do
  defimpl Jason.Encoder, for: Money do
    alias Books.Money, as: AwMoney

    def encode(%Money{} = money, opts) do
      Jason.Encode.value(AwMoney.money_to_str(money), opts)
    end
  end

  def money_to_str(money) do
    Money.to_string(money,
      delimeter: ".",
      separator: "",
      symbol: false,
      symbol_space: false
    )
  end

  defp money_parse(money), do: Money.parse!(money, nil, delimeter: ".")

  def parse(nil), do: Money.new(0)
  def parse(%Money{} = money), do: money
  def parse(money) when is_binary(money), do: money_parse(money)

  def parse(%{"currency" => currency, "value" => value}) do
    Money.parse!(value, String.to_atom(currency), delimeter: ".")
  end

  def percentage(%Money{amount: v}, p) when is_number(p) do
    Money.new(trunc(v * p / 100))
  end

  def percentage(%Money{amount: v}, %Money{amount: p}) do
    Money.new(trunc(v * p / 100))
  end

  def currency do
    Application.get_env(:money, :default_currency)
    |> to_string()
  end
end
