defmodule Books.AdsTest do
  use Books.DataCase

  alias Books.Ads

  describe "ads_carousel" do
    alias Books.Ads.Carousel

    import Books.AdsFixtures

    @invalid_attrs %{enable: nil, image: nil}

    test "list_ads_carousel/0 returns all ads_carousel" do
      carousel = carousel_fixture()
      assert carousel in Ads.list_ads_carousel()
    end

    test "get_carousel!/1 returns the carousel with given id" do
      carousel = carousel_fixture()
      assert Ads.get_carousel!(carousel.id) == carousel
    end

    test "create_carousel/1 with valid data creates a carousel" do
      book = Books.Catalog.get_book_by_slug("erlang-i")

      valid_attrs = %{
        enable: true,
        image: "some image",
        type: :book,
        book_id: book.id
      }

      assert {:ok, %Carousel{} = carousel} = Ads.create_carousel(valid_attrs)
      assert carousel.enable == true
      assert carousel.image == "some image"
      assert carousel.type == :book
      assert is_nil(carousel.bundle_id)
    end

    test "create_carousel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ads.create_carousel(@invalid_attrs)
    end

    test "update_carousel/2 with valid data updates the carousel" do
      carousel = carousel_fixture()
      update_attrs = %{enable: false, image: "some updated image"}

      assert {:ok, %Carousel{} = carousel} = Ads.update_carousel(carousel, update_attrs)
      assert carousel.enable == false
      assert carousel.image == "some updated image"
    end

    test "update_carousel/2 with invalid data returns error changeset" do
      carousel = carousel_fixture()
      assert {:error, %Ecto.Changeset{}} = Ads.update_carousel(carousel, @invalid_attrs)
      assert carousel == Ads.get_carousel!(carousel.id)
    end

    test "delete_carousel/1 deletes the carousel" do
      carousel = carousel_fixture()
      assert {:ok, %Carousel{}} = Ads.delete_carousel(carousel)
      assert_raise Ecto.NoResultsError, fn -> Ads.get_carousel!(carousel.id) end
    end

    test "change_carousel/1 returns a carousel changeset" do
      carousel = carousel_fixture()
      assert %Ecto.Changeset{} = Ads.change_carousel(carousel)
    end
  end

  describe "bundle" do
    import Books.CatalogFixtures

    setup do
      category = category_fixture()

      books = [
        book_i = book_fixture(%{slug: "book-i", category_id: category.id}),
        book_ii = book_fixture(%{slug: "book-ii", category_id: category.id}),
        book_iii = book_fixture(%{slug: "book-iii", category_id: category.id})
      ]

      formats = [
        format_fixture(%{book_id: book_i.id}),
        format_fixture(%{book_id: book_ii.id}),
        format_fixture(%{book_id: book_iii.id})
      ]

      %{books: books, formats: formats}
    end

    test "create bundle", %{formats: formats} do
      ids = Enum.map(formats, & &1.id)

      assert {:ok, bundle} =
               Books.Ads.create_bundle(%{
                 "bundle_formats" => ids,
                 "slug" => "books",
                 "enabled" => "true",
                 "name" => "¡Libros!",
                 "description" => "¡Todos los libros!",
                 "keywords" => "book, libro, livro",
                 "price" => "10,00 €",
                 "real_price" => "12,00 €"
               })

      assert ids -- Enum.map(bundle.formats, & &1.id) == []
      assert "books" == bundle.slug
      assert bundle.enabled
      assert "¡Libros!" == bundle.name
      assert "¡Todos los libros!" == bundle.description
      assert "book, libro, livro" == bundle.keywords
    end

    test "delete bundle", %{formats: formats} do
      ids = Enum.map(formats, & &1.id)

      assert {:ok, bundle} =
               Books.Ads.create_bundle(%{
                 "bundle_formats" => ids,
                 "slug" => "books",
                 "enabled" => "true",
                 "name" => "¡Libros!",
                 "description" => "¡Todos los libros!",
                 "keywords" => "book, libro, livro",
                 "price" => "10,00 €",
                 "real_price" => "12,00 €"
               })

      Books.Ads.get_bundle!(bundle.id)

      assert {:ok, bundle} =
               Books.Ads.delete_bundle(bundle)

      assert_raise Ecto.NoResultsError, fn -> Books.Ads.get_bundle!(bundle.id) end
    end

    test "update bundle", %{formats: formats} do
      ids = Enum.map(formats, & &1.id)

      assert {:ok, bundle} =
               Books.Ads.create_bundle(%{
                 "bundle_formats" => [hd(ids)],
                 "slug" => "books",
                 "enabled" => "true",
                 "name" => "¡Libros antiguos!",
                 "description" => "¡Todos los libros antiguos!",
                 "keywords" => "libro, vintage",
                 "price" => "10,00 €",
                 "real_price" => "12,00 €"
               })

      assert [hd(ids)] == Enum.map(bundle.formats, & &1.id)

      assert {:ok, bundle} =
               Books.Ads.update_bundle(bundle, %{
                 "bundle_formats" => ids,
                 "name" => "¡Libros!",
                 "description" => "¡Todos los libros!",
                 "keywords" => "book, libro, livro"
               })

      assert ids -- Enum.map(bundle.formats, & &1.id) == []
      assert "books" == bundle.slug
      assert bundle.enabled
      assert "¡Libros!" == bundle.name
      assert "¡Todos los libros!" == bundle.description
      assert "book, libro, livro" == bundle.keywords
    end
  end
end
