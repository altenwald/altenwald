defmodule BooksAdmin.OffersController do
  use BooksAdmin, :controller
  require Logger
  alias Books.{Ads, Catalog}

  defp default_return_to(conn) do
    Routes.offers_path(conn, :index)
  end

  defp list_statuses do
    [
      {gettext("All"), "all"},
      {gettext("Active"), "active"},
      {gettext("Expired / Used"), "expired"}
    ]
  end

  def index(conn, params) do
    defaults = %{"status" => "all", "group" => ""}
    filters = Map.merge(defaults, params["filters"] || %{})

    render(conn, "index.html",
      title: gettext("Offers"),
      page: Ads.list_offers_paginated(params),
      filters: filters,
      offer_groups: list_offer_groups_filters(),
      statuses: list_statuses()
    )
  end

  def delete(conn, %{"id" => offer_id} = params) do
    return_to = params["return_to"] || default_return_to(conn)
    offer = Ads.get_offer!(offer_id)

    case Ads.delete_offer(offer) do
      {:ok, _offer} ->
        conn
        |> put_flash(:info, gettext("Offer removed successfully!"))
        |> redirect(to: return_to)

      {:error, reason} ->
        Logger.error("cannot remove #{offer_id}, reason: #{inspect(reason)}")

        conn
        |> put_flash(:error, gettext("Cannot remove offer, maybe it's in use"))
        |> redirect(to: return_to)
    end
  end

  def new(conn, params) do
    offer = Ads.new_offer()
    return_to = params["return_to"] || default_return_to(conn)
    render(conn, "new.html", options(offer, Ads.change_offer(offer), return_to))
  end

  def edit(conn, %{"id" => id} = params) do
    offer = Ads.get_offer!(id)
    return_to = params["return_to"] || default_return_to(conn)
    render(conn, "edit.html", options(offer, Ads.change_offer(offer), return_to))
  end

  defp options(offer, changeset, return_to) do
    [
      title:
        case offer do
          %_{id: nil} -> gettext("New offer")
          _ -> gettext("Update offer")
        end,
      changeset: changeset,
      offer: offer,
      types: list_types(),
      discount_types: list_discount_types(),
      formats: list_all_formats(),
      offer_groups: list_offer_groups(),
      return_to: return_to
    ]
  end

  defp list_all_formats do
    for format <- Catalog.list_all_formats() do
      {"[#{format.name}] #{Catalog.get_full_book_title(format.book)}", format.id}
    end
  end

  defp list_types do
    [
      {gettext("Choose one..."), ""},
      {gettext("Code"), "code"},
      {gettext("Combo"), "combo"},
      {gettext("Time"), "time"}
    ]
  end

  defp list_discount_types do
    [
      {gettext("Choose one..."), ""},
      {gettext("Money"), "money"},
      {gettext("Percentage (items)"), "percentage"},
      {gettext("Percentage (shipping)"), "shipping"}
    ]
  end

  defp list_offer_groups do
    Ads.list_offer_groups()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp list_offer_groups_filters do
    Ads.list_offer_groups()
    |> Enum.map(& &1.name)
    |> then(&[{gettext("No group"), "(nil)"} | &1])
  end

  def update(conn, %{"id" => offer_id, "offer" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)
    offer = Ads.get_offer!(offer_id)

    case Ads.update_offer(offer, params) do
      {:ok, _offer} ->
        conn
        |> put_flash(:info, gettext("Offer modified successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot update offer: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("edit.html", options(offer, changeset, return_to))
    end
  end

  def create(conn, %{"offer" => params} = global_params) do
    return_to = global_params["return_to"] || default_return_to(conn)

    case Ads.create_offer(params) do
      {:ok, _offer} ->
        conn
        |> put_flash(:info, gettext("Offer created successfully!"))
        |> redirect(to: return_to)

      {:error, changeset} ->
        Logger.error("cannot create offer: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, gettext("Found validation errors, see below"))
        |> render("new.html", options(Ads.new_offer(), changeset, return_to))
    end
  end
end
