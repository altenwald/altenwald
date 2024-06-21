defmodule BooksAdmin.Router do
  use Phoenix.Router

  pipeline :admin_browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, {BooksAdmin.Layouts, :root})
  end

  scope "/", BooksAdmin do
    pipe_through([:admin_browser])

    get("/", HomeController, :index)
    get("/dashboard", HomeController, :dashboard)
    resources("/cart", CartController)
    delete("/cart/:id/stop", CartController, :stop)
    resources("/authors", AuthorsController)
    resources("/offers", OffersController)
    resources("/bundles", BundlesController)
    resources("/finance", FinanceController, except: [:new, :show])
    get("/finance/new-income", FinanceController, :new_income)
    get("/finance/new-outcome", FinanceController, :new_outcome)
    get("/finance/:id/edit-income", FinanceController, :edit_income)
    get("/finance/:id/edit-outcome", FinanceController, :edit_outcome)

    resources("/accounts", AccountsController) do
      resources("/bookshelf", BookshelfController)
    end

    resources("/ads", AdsController)

    resources("/catalog", CatalogController) do
      resources("/authors", BookAuthorsController)
      post("/contents/bulk-action", ContentsController, :bulk_action)
      resources("/contents", ContentsController)

      resources("/formats", FormatsController) do
        resources("/files", DigitalFilesController)
      end

      resources("/projects", ProjectsController)
      resources("/cross-selling", CrossSellingController)
      resources("/reviews", ReviewsController)
    end

    resources("/landings", LandingsController)
  end
end
