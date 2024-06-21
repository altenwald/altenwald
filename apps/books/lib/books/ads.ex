defmodule Books.Ads do
  @moduledoc """
  The Ads context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Books.Ads.Offer
  alias Books.Ads.OfferGroup
  alias Books.Cart.OrderOffer
  alias Books.Repo

  alias Books.Ads.{Bundle, Carousel, Offer}

  def get_offer_by_code(code) do
    now = NaiveDateTime.utc_now()

    from(
      o in Offer,
      left_join: oo in OrderOffer,
      on: oo.offer_id == o.id,
      where: o.type == :code,
      where: o.code == ^code,
      where: is_nil(o.expiration) or o.expiration > ^now,
      group_by: o.id,
      having: is_nil(o.max_uses) or count(oo.id) < o.max_uses,
      preload: [:applies],
      order_by: [desc: :inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Returns the list of ads_carousel.

  ## Examples

      iex> list_ads_carousel()
      [%Carousel{}, ...]

  """
  def list_ads_carousel do
    from(c in Carousel, order_by: c.priority, preload: [:book, :bundle])
    |> Repo.all()
  end

  defp list_offers_query(filters) do
    from(o in Offer,
      as: :offers,
      left_join: oo in assoc(o, :order_offers),
      as: :order_offers,
      order_by: o.name,
      select: %Offer{o | uses: count(oo.id)},
      group_by: o.id,
      preload: [:applies, :formats, :offer_group]
    )
    |> maybe_filter_status(filters["status"] || "all")
    |> maybe_filter_group(filters["group"] || "")
  end

  defp maybe_filter_group(query, ""), do: query

  defp maybe_filter_group(query, "(nil)") do
    where(query, [offers: o], is_nil(o.offer_group_id))
  end

  defp maybe_filter_group(query, group_name) do
    from(o in query,
      join: og in assoc(o, :offer_group),
      where: og.name == ^group_name
    )
  end

  defp maybe_filter_status(query, "all"), do: query

  defp maybe_filter_status(query, "active") do
    having(
      query,
      [offers: o, order_offers: oo],
      (is_nil(o.expiration) or o.expiration >= ^NaiveDateTime.utc_now()) and
        (is_nil(o.max_uses) or o.max_uses > count(oo.id))
    )
  end

  defp maybe_filter_status(query, "expired") do
    having(
      query,
      [offers: o, order_offers: oo],
      (not is_nil(o.expiration) and
         o.expiration < ^NaiveDateTime.utc_now()) or
        (not is_nil(o.max_uses) and o.max_uses <= count(oo.id))
    )
  end

  def list_offers(params \\ %{}) do
    list_offers_query(params["filters"] || %{})
    |> Repo.all()
  end

  def list_offers_paginated(params) do
    list_offers_query(params["filters"] || %{})
    |> Repo.paginate(params)
  end

  def list_offer_groups do
    Repo.all(OfferGroup)
  end

  def list_bundles do
    Bundle
    |> Repo.all()
    |> Repo.preload(:formats)
  end

  @doc """
  Gets a single carousel.

  Raises `Ecto.NoResultsError` if the Carousel does not exist.

  ## Examples

      iex> get_carousel!(123)
      %Carousel{}

      iex> get_carousel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_carousel!(id) do
    Carousel
    |> Repo.get!(id)
    |> Repo.preload([:book, :bundle])
  end

  def get_offer!(id) do
    Offer
    |> Repo.get!(id)
    |> Repo.preload([:applies, :format_offers, :formats, :offer_applies])
  end

  def get_bundle!(id) do
    Bundle
    |> Repo.get!(id)
    |> Repo.preload([:formats, :bundle_formats])
  end

  def get_bundle_by_slug!(slug) do
    Bundle
    |> Repo.get_by!(slug: slug)
    |> Repo.preload([:formats, :bundle_formats])
  end

  @doc """
  Creates a carousel.

  ## Examples

      iex> create_carousel(%{field: value})
      {:ok, %Carousel{}}

      iex> create_carousel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_carousel(attrs \\ %{}) do
    %Carousel{}
    |> Carousel.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, carousel} -> {:ok, Repo.preload(carousel, [:book, :bundle])}
      {:error, _} = error -> error
    end
  end

  def create_offer(attrs \\ %{}) do
    old_format_offers = attrs["format_offers"]
    old_offer_applies = attrs["offer_applies"]

    attrs =
      attrs
      |> process_offer_applies()
      |> process_format_offers()
      |> tap(&Logger.debug("create_offer: #{inspect(&1)}"))

    %Offer{}
    |> Offer.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, offer} ->
        {:ok, Repo.preload(offer, [:applies, :formats, :format_offers, :offer_applies])}

      {:error, changeset} ->
        changeset = put_in(changeset.params["format_offers"], old_format_offers)
        changeset = put_in(changeset.params["offer_applies"], old_offer_applies)
        {:error, changeset}
    end
  end

  def create_code_offers(base_name, num, amount, type, applies) when is_list(applies) do
    hi =
      Hashids.new(
        salt: to_string(__MODULE__),
        min_len: max(floor(:math.log10(num)) + 1, 6),
        alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      )

    Enum.each(
      1..num,
      fn n ->
        n = Hashids.encode(hi, n)
        name = "#{base_name}#{n}"

        attrs = %{
          "name" => name,
          "code" => name,
          "max_uses" => 1,
          "type" => "code",
          "discount_amount" => amount,
          "discount_type" => type,
          "offer_applies" => applies
        }

        create_offer(attrs)
      end
    )
  end

  def create_bundle(attrs) do
    old_bundle_formats = attrs["bundle_formats"]
    attrs = process_bundle_formats(attrs)

    %Bundle{}
    |> Bundle.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, bundle} ->
        {:ok, Repo.preload(bundle, :formats)}

      {:error, changeset} ->
        {:error, put_in(changeset.params["bundle_formats"], old_bundle_formats)}
    end
  end

  def new_offer do
    %Offer{}
    |> Repo.preload([:format_offers, :offer_applies])
  end

  def new_carousel do
    %Carousel{}
  end

  def new_bundle do
    %Bundle{}
    |> Repo.preload([:bundle_formats])
  end

  @doc """
  Updates a carousel.

  ## Examples

      iex> update_carousel(carousel, %{field: new_value})
      {:ok, %Carousel{}}

      iex> update_carousel(carousel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_carousel(%Carousel{} = carousel, attrs) do
    carousel
    |> Carousel.changeset(attrs)
    |> Repo.update()
  end

  def update_offer(%Offer{} = offer, attrs) do
    attrs =
      attrs
      |> process_offer_applies()
      |> process_format_offers()
      |> tap(&Logger.debug("update_offer: #{inspect(&1)}"))

    offer
    |> Offer.changeset(attrs)
    |> Repo.update()
  end

  defp process_offer_applies(%{"offer_applies" => offer_applies} = params) do
    for format_id <- offer_applies do
      %{"format_id" => format_id}
    end
    |> then(&Map.put(params, "offer_applies", &1))
  end

  defp process_offer_applies(params) do
    Map.put(params, "offer_applies", [])
  end

  defp process_format_offers(%{"format_offers" => format_offers} = params) do
    for format_id <- format_offers do
      %{"format_id" => format_id}
    end
    |> then(&Map.put(params, "format_offers", &1))
  end

  defp process_format_offers(params) do
    Map.put(params, "format_offers", [])
  end

  def update_bundle(%Bundle{} = bundle, attrs) do
    attrs = process_bundle_formats(attrs)

    bundle
    |> Repo.preload(:bundle_formats)
    |> Bundle.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, bundle} ->
        {:ok, Repo.preload(bundle, :formats, force: true)}

      {:error, _} = error ->
        error
    end
  end

  defp process_bundle_formats(%{"bundle_formats" => bundle_formats} = params) do
    for format_id <- bundle_formats do
      %{"format_id" => format_id}
    end
    |> then(&Map.put(params, "bundle_formats", &1))
  end

  @doc """
  Deletes a carousel.

  ## Examples

      iex> delete_carousel(carousel)
      {:ok, %Carousel{}}

      iex> delete_carousel(carousel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_carousel(%Carousel{} = carousel) do
    Repo.delete(carousel)
  end

  def delete_offer(%Offer{} = offer) do
    offer
    |> Offer.delete_changeset()
    |> Repo.delete()
  end

  def delete_bundle(%Bundle{} = bundle) do
    Repo.delete(bundle)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking carousel changes.

  ## Examples

      iex> change_carousel(carousel)
      %Ecto.Changeset{data: %Carousel{}}

  """
  def change_carousel(%Carousel{} = carousel, attrs \\ %{}) do
    Carousel.changeset(carousel, attrs)
  end

  def change_offer(%Offer{} = offer, attrs \\ %{}) do
    Offer.changeset(offer, attrs)
  end

  def change_bundle(%Bundle{} = bundle, attrs \\ %{}) do
    Bundle.changeset(bundle, attrs)
  end
end
