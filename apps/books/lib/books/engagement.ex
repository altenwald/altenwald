defmodule Books.Engagement do
  require Logger
  import Ecto.Query, only: [from: 2]
  alias Books.{Accounts, Catalog, Repo}
  alias Books.Engagement.{Subscribe, VisualAlert}

  def alerts_by_lang(query \\ VisualAlert, lang) do
    from(va in query, where: va.lang == ^lang and va.enabled)
    |> Repo.all()
  end

  @spec new_subscription() :: Ecto.Changeset.t()
  def new_subscription, do: Subscribe.changeset()

  @spec new_subscription(map()) :: {:ok, Subscribe.t()} | {:error, Ecto.Changeset.t()}
  def new_subscription(attrs), do: Subscribe.changeset(attrs)

  @spec save(map(), [String.t()], String.t()) :: boolean()
  def save(%{email: email, full_name: full_name}, tags, lang) do
    {first_name, last_name} =
      case String.split(full_name, " ", parts: 2, trim: true) do
        [full_name] -> {full_name, ""}
        [first_name, last_name] -> {first_name, last_name}
      end

    data = %{
      "email_address" => email,
      "status" => "subscribed",
      "language" => lang,
      "tags" => tags,
      "merge_fields" => %{
        "FNAME" => first_name,
        "LNAME" => last_name
      }
    }

    Logger.info("subscribe [#{first_name}] [#{last_name}] to [#{inspect(tags)}]")

    case Mailchimp.add_member(data) do
      {:ok, %{"status" => 400, "title" => "Member Exists"}} ->
        Logger.warning("user #{email} was already registered by mailchimp")
        res = Mailchimp.add_tags(email, tags)
        Logger.debug("add tags output => #{inspect(res)}")
        true

      {:ok, %{"status" => "subscribed"}} ->
        true

      {:ok, %{"status" => status, "title" => msg}} ->
        Logger.error("status=#{status} msg=#{msg}")
        false

      {:error, error} ->
        Logger.error("cannot add email #{email} => #{inspect(error)}")
        false
    end
  end

  defp lang_tag("en"), do: ["english"]
  defp lang_tag("es"), do: ["spanish"]
  defp lang_tag(_ohter), do: []

  def get_tags_by_book(book, lang \\ true)

  def get_tags_by_book(book, true) do
    [get_tag_by_book(book) | lang_tag(book.lang)]
  end

  def get_tags_by_book(book, false) do
    [get_tag_by_book(book)]
  end

  defp get_tag_by_book(book) do
    "#{book.slug}-#{book.edition}ed-info"
  end

  def get_book_tags do
    Catalog.list_books_simple()
    |> Enum.map(
      &%{
        name: Catalog.get_book_title(&1),
        slug: &1.slug,
        lang: &1.lang,
        tag: get_tag_by_book(&1)
      }
    )
    |> Enum.sort_by(& &1.name)
  end

  def get_category_tags do
    Catalog.list_books_simple()
    |> Repo.preload(:category)
    |> Enum.map(
      &%{
        category: &1.category,
        tag: get_tag_by_book(&1)
      }
    )
    |> Enum.group_by(& &1.category, & &1.tag)
  end

  def user_subscribe_book(user, book) do
    user_subscribe_tags(user, get_tags_by_book(book, true))
  end

  def user_unsubscribe_book(user, book) do
    user_unsubscribe_tags(user, get_tags_by_book(book, false))
  end

  def user_subscribe_tags(user, tags) do
    tags =
      user.mailling_tags
      |> MapSet.new()
      |> MapSet.union(MapSet.new(tags))
      |> MapSet.to_list()

    Accounts.update_settings(user, %{"mailling_tags" => tags})
  end

  def user_unsubscribe_tags(user, tags) do
    tags =
      user.mailling_tags
      |> MapSet.new()
      |> MapSet.difference(MapSet.new(tags))
      |> MapSet.to_list()

    Accounts.update_settings(user, %{"mailling_tags" => tags})
  end
end
