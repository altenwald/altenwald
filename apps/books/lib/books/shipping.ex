defmodule Books.Shipping do
  import Ecto.Query, only: [from: 2]

  alias Books.Cart.Order
  alias Books.Repo

  @spain 10_00
  @europe 10_00
  @rest_of_world 10_00

  def europe_countries do
    for c <- Countries.filter_by(:region, "Europe"), do: c.alpha2
  end

  def get_amount(nil), do: Money.new(@rest_of_world)
  def get_amount("ES"), do: Money.new(@spain)

  def get_amount(country_code) do
    if country_code in europe_countries() do
      Money.new(@europe)
    else
      Money.new(@rest_of_world)
    end
  end

  def get_stats_from(date) do
    from(o in Order,
      select: [o.shipping_status, count(fragment("distinct ?", o.id))],
      where: o.updated_at > ^date,
      group_by: o.shipping_status
    )
    |> Repo.all()
  end
end
