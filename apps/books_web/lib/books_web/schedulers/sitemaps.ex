defmodule BooksWeb.Schedulers.Sitemaps do
  use Cronex.Scheduler
  use Sitemap

  alias Books.Catalog
  alias Books.Landings
  alias Books.Posts
  alias BooksWeb.Endpoint
  alias BooksWeb.PostsHTML
  alias BooksWeb.Router.Helpers, as: Routes

  every :day, at: "9:00" do
    generate()
  end

  def generate do
    Sitemap.Config.set(:files_path, "#{:code.priv_dir(:books_web)}/static/sitemaps/")
    Sitemap.Config.set(:host, "https://altenwald.com")

    create do
      add(Routes.catalog_path(Endpoint, :index),
        priority: 1.0,
        changefreq: "daily",
        expires: nil
      )

      Catalog.list_books()
      |> Enum.each(fn book ->
        add(Routes.catalog_path(Endpoint, :book, book.slug),
          priority: 1.0,
          changefreq: "daily",
          expires: nil
        )
      end)

      Landings.list_landings()
      |> Enum.each(fn landing ->
        Enum.each(landing.slugs, fn slug ->
          add(Routes.landing_path(Endpoint, :show, slug),
            priority: 1.0,
            changefreq: "daily",
            expires: nil
          )

          add(slug,
            priority: 1.0,
            changefreq: "daily",
            expires: nil
          )
        end)
      end)

      Posts.list_posts("es")
      |> Enum.each(fn post ->
        add(PostsHTML.post_path(Endpoint, post),
          priority: 0.75,
          changefreq: "weekly",
          lastmod: post.updated_at,
          expires: nil
        )
      end)

      Posts.list_posts("en")
      |> Enum.each(fn post ->
        add("/en" <> PostsHTML.post_path(Endpoint, post),
          priority: 0.75,
          changefreq: "weekly",
          lastmod: post.updated_at,
          expires: nil
        )
      end)

      add(Routes.legal_path(Endpoint, :privacy_es),
        priority: 0.25,
        changefreq: "weekly",
        expires: nil
      )

      add("/en" <> Routes.legal_path(Endpoint, :privacy_en),
        priority: 0.25,
        changefreq: "weekly",
        expires: nil
      )

      add(Routes.legal_path(Endpoint, :cookies_es),
        priority: 0.25,
        changefreq: "weekly",
        expires: nil
      )

      add("/en" <> Routes.legal_path(Endpoint, :cookies_en),
        priority: 0.25,
        changefreq: "weekly",
        expires: nil
      )

      add(Routes.legal_path(Endpoint, :tos_es),
        priority: 0.25,
        changefreq: "weekly",
        expires: nil
      )

      add("/en" <> Routes.legal_path(Endpoint, :tos_en),
        priority: 0.25,
        changefreq: "weekly",
        expires: nil
      )

      add(Routes.legal_path(Endpoint, :about_es),
        priority: 0.25,
        changefreq: "weekly",
        expires: nil
      )

      add("/en" <> Routes.legal_path(Endpoint, :about_en),
        priority: 0.25,
        changefreq: "weekly",
        expires: nil
      )
    end

    # notify search engines (currently Google and Bing) of the updated sitemap
    ping()
  end
end
