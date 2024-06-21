defimpl Phoenix.HTML.Safe, for: Money do
  def to_iodata(money), do: to_string(money)
end
