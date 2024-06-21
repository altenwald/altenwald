defmodule Books.AdsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Books.Ads` context.
  """

  @doc """
  Generate a carousel.
  """
  def carousel_fixture(attrs \\ %{}) do
    book = Books.Catalog.get_book_by_slug("erlang-i")

    {:ok, carousel} =
      attrs
      |> Enum.into(%{
        "enable" => true,
        "image" => "some image",
        "type" => "book",
        "book_id" => book.id
      })
      |> Books.Ads.create_carousel()

    carousel
  end
end
