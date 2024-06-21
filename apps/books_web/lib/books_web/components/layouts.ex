defmodule BooksWeb.Layouts do
  use BooksWeb, :html
  alias Books.{Catalog, Posts}
  import BooksWeb.MarkdownHelpers
  import Books.Accounts, only: [user_admin?: 1, user_role?: 2]
  import Books.Catalog, only: [get_book_authors: 2]
  import BooksWeb.{BookHelpers, CartHelpers}
  import BooksWeb.{MarkdownHelpers, ImageHelpers}

  defp google_tag_id do
    Application.get_env(:books_web, :google_tag_id)
  end

  def google_tagmanager_id do
    Application.get_env(:books_web, :google_tagmanager_id)
  end

  def facebook_id, do: Application.get_env(:books_web, :facebook_id)

  def html2txt(html) do
    html
    |> HtmlSanitizeEx.strip_tags()
    |> String.trim()
  end

  defp book_authors(authors) do
    authors
    |> Enum.filter(&(&1.role == :author))
    |> Enum.map(& &1.author.full_name)
  end

  def ld_json_book(conn, book, format) do
    %{
      "@type" => "Book",
      "copyrightHolder" => %{
        "@type" => "Organization",
        "name" => "Altenwald"
      },
      "author" =>
        Enum.map(book_authors(book.roles), fn author ->
          %{
            "@type" => "Person",
            "name" => author
          }
        end),
      "bookEdition" => to_string(book.edition),
      "copyrightYear" => to_string(get_copyright_year(book)),
      "abstract" => html2txt(book.description),
      "keywords" => book.keywords,
      "inLanguage" => get_language(book.lang),
      "isbn" => book.isbn,
      "name" => Catalog.get_book_title(book),
      "numberOfPages" => book.num_pages,
      "datePublished" => to_string(book.release || ""),
      "publisher" => %{
        "@type" => "Organization",
        "name" => "Altenwald"
      },
      "image" => static_url(conn, "/images/covers/#{get_image(:small, book)}"),
      "review" => Enum.map(book.reviews, &ld_json_review(book, &1))
    }
    |> maybe_add("bookFormat", format, &get_book_format/1)
    |> maybe_add("offers", format, &offers/1)
  end

  defp maybe_add(map, _field, nil, _f), do: map
  defp maybe_add(map, field, value, f), do: Map.put(map, field, f.(value))

  defp offers(format) do
    %{
      "@type" => "Offer",
      "availability" => "https://schema.org/InStock",
      "price" => Books.Money.money_to_str(format.price),
      "priceCurrency" => Books.Money.currency()
    }
  end

  defp locale(lang, <<"/", _old_lang::binary-size(2), "/", uri::binary>>),
    do: locale(lang, "/" <> uri)

  defp locale(lang, <<"/", _old_lang::binary-size(2), "/">>), do: locale(lang, "/")
  defp locale(lang, <<"/", _old_lang::binary-size(2)>>), do: locale(lang, "/")
  defp locale(nil, uri), do: uri
  defp locale(lang, uri), do: Path.join("/#{lang}", uri)

  defp path_to_url(path) do
    Path.join(BooksWeb.Endpoint.url(), path)
  end

  defp get_language("es"), do: "es_ES"
  defp get_language(_other), do: "en_GB"

  defp get_copyright_year(%_{release: nil}), do: Date.utc_today().year
  defp get_copyright_year(%_{release: release}), do: release.year

  defp get_book_format(%_{name: :paper}), do: "http://schema.org/Paperback"
  defp get_book_format(_), do: "http://schema.org/EBook"

  def ld_json_review(book, review) do
    %{
      "@type" => "Review",
      "author" => review.full_name,
      "datePublished" => to_string(NaiveDateTime.to_date(review.inserted_at)),
      "reviewBody" => review.content,
      "itemReviewed" => %{
        "@type" => "Product",
        "name" => Catalog.get_book_title(book),
        "sku" => book.isbn
      },
      "reviewRating" => %{
        "@type" => "Rating",
        "bestRating" => "50",
        "ratingValue" => review.value,
        "worstRating" => "0"
      }
    }
  end

  def ld_json_faqs(faqs) do
    main =
      for faq <- faqs do
        answer = to_html(faq.answer)

        %{
          "@type" => "Question",
          "name" => faq.question,
          "acceptedAnswer" => %{
            "@type" => "Answer",
            "text" => answer
          }
        }
      end

    %{
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => main
    }
    |> Jason.encode!()
  end

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  defdelegate get_image(type, book), to: BooksWeb.CatalogHTML

  defp get_full_title(post, size) do
    post
    |> get_full_title()
    |> limit_text(size)
  end

  defp get_width(nil), do: ""

  defp get_width(image) do
    image
    |> get_post_image()
    |> info()
    |> case do
      %{width: width} -> to_string(width)
      _ -> ""
    end
  end

  defp get_height(nil), do: ""

  defp get_height(image) do
    image
    |> get_post_image()
    |> info()
    |> case do
      %{height: height} -> to_string(height)
      _ -> ""
    end
  end

  defp get_content_type(image) do
    MIME.type(image)
  end

  defp to_text(markdown, size) do
    markdown
    |> to_text()
    |> limit_text(size)
  end

  defp limit_text(nil, _size), do: ""

  defp limit_text(text, size) when byte_size(text) < size, do: text

  defp limit_text(text, size) do
    text
    |> String.slice(0, size - 4)
    |> String.replace_suffix("", "...")
  end

  defdelegate get_full_title(post), to: Posts

  embed_templates "layouts/*"
end
