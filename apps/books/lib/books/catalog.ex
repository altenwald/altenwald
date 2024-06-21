defmodule Books.Catalog do
  import Ecto.Query, only: [from: 2]
  alias Books.Accounts.User
  alias Books.Balances.Income

  alias Books.Catalog.{
    Author,
    Book,
    BookAuthor,
    BookCrossSelling,
    Category,
    Content,
    DigitalFile,
    Format,
    Isbn,
    Project,
    Review
  }

  alias Books.Repo
  alias Ecto.Multi

  def missing_files do
    base = Application.get_env(:books_web, :files_path)

    Books.Catalog.DigitalFile
    |> Repo.all()
    |> Enum.map(&Path.join(base, &1.filename))
    |> Enum.reject(&File.exists?/1)
    |> case do
      [] ->
        true

      files ->
        Enum.each(files, &IO.puts/1)
        false
    end
  end

  def search_author(name) do
    from(a in Author, where: ilike(a.full_name, ^"%#{name}%"), limit: 1)
    |> Repo.one()
  end

  def books_by_author(author_id) do
    from(
      b in Book,
      join: ba in assoc(b, :roles),
      where: ba.author_id == ^author_id and b.enabled,
      order_by: [asc: b.title, asc: b.subtitle]
    )
    |> Repo.all()
  end

  def create_book(attrs \\ %{}) do
    %Book{}
    |> Book.changeset(attrs)
    |> Repo.insert()
  end

  def update_book(book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  def get_author(author_id) do
    Repo.get(Author, author_id)
    |> Repo.preload(:user)
  end

  def get_author_from_user(%User{} = user) do
    %User{author: author} = Repo.preload(user, :author)
    author
  end

  def get_book(id) do
    Repo.get(Book, id)
  end

  def get_book_authors(book, opts \\ :full_link)

  def get_book_authors(book, :full) do
    book.roles
    |> Enum.filter(&(&1.role == :author))
    |> Enum.map_join(", ", & &1.author.full_name)
  end

  def get_book_authors(book, :short) do
    book.roles
    |> Enum.filter(&(&1.role == :author))
    |> Enum.map_join(", ", & &1.author.short_name)
  end

  def get_book_authors(book, :full_link) do
    book.roles
    |> Enum.filter(&(&1.role == :author))
    |> Enum.map_join(", ", &"<a href='#{&1.author.url}'>#{&1.author.full_name}</a>")
  end

  def get_book_authors(book, :short_link) do
    book.roles
    |> Enum.filter(&(&1.role == :author))
    |> Enum.map_join(", ", &"<a href='#{&1.author.url}'>#{&1.author.short_name}</a>")
  end

  def get_book_author(book_author_id) do
    Repo.get(BookAuthor, book_author_id)
  end

  def get_book_id_by_slug(slug) do
    if book = Repo.get_by(Book, slug: slug), do: book.id
  end

  def get_book_by_slug(slug, full_preload \\ false) do
    Book
    |> Repo.get_by(slug: slug)
    |> Repo.preload(Book.preload(full_preload))
  end

  def get_cross_selling(cross_selling_id) do
    Repo.get(BookCrossSelling, cross_selling_id)
  rescue
    Ecto.Query.CastError -> nil
  end

  def get_review(review_id) do
    Repo.get(Review, review_id)
  end

  def list_all_books do
    from(b in Book, order_by: [asc: b.release, asc: b.presale, asc: b.inserted_at])
    |> Repo.all()
  end

  def list_all_books_with_income do
    from(b in Book,
      left_join: i in Income,
      on: b.id == i.book_id,
      select: %Book{b | income: sum(i.amount)},
      group_by: b.id,
      order_by: [asc: b.release, asc: b.presale, asc: b.inserted_at]
    )
    |> Repo.all()
  end

  def list_all_formats do
    from(
      f in Format,
      join: b in assoc(f, :book),
      order_by: [b.title, b.subtitle, b.edition, f.name],
      preload: :book
    )
    |> Repo.all()
  end

  def list_authors do
    from(a in Author, order_by: a.short_name)
    |> Repo.all()
  end

  def list_books do
    list_books_simple()
    |> Repo.preload([:category, formats: Format.preload(), roles: :author])
  end

  def list_books_simple do
    from(b in Book, where: b.enabled == true, order_by: b.inserted_at)
    |> Repo.all()
  end

  def list_all_books_simple do
    from(b in Book, order_by: [b.title, b.subtitle, b.edition])
    |> Repo.all()
  end

  def list_isbn do
    from(i in Isbn, preload: :book, order_by: i.isbn)
    |> Repo.all()
  end

  def get_book_title(nil), do: nil

  def get_book_title(%Book{subtitle: subtitle, title: title}) when subtitle in ["", nil],
    do: title

  def get_book_title(book), do: "#{book.title}: #{book.subtitle}"

  def get_full_book_title(%Book{edition: 1} = book), do: get_book_title(book)
  def get_full_book_title(book), do: "#{get_book_title(book)} (#{book.edition}ed)"

  defp in_the_past?(date), do: Date.diff(Date.utc_today(), date) >= 0

  def book_released?(book) do
    book.release != nil and in_the_past?(book.release)
  end

  def book_in_presale?(book) do
    book.presale != nil and in_the_past?(book.presale)
  end

  def can_be_bought?(book), do: book_released?(book) or book_in_presale?(book)

  def change_book(book, changes \\ %{}) do
    Book.changeset(book, changes)
  end

  def change_book_author(book_author, changes \\ %{}) do
    BookAuthor.changeset(book_author, changes)
  end

  def change_content(content, changes \\ %{}) do
    Content.changeset(content, changes)
  end

  def change_review(review, changes \\ %{}) do
    Review.changeset(review, changes)
  end

  def change_cross_selling(cross_selling, changes \\ %{}) do
    BookCrossSelling.changeset(cross_selling, changes)
  end

  def change_digital_file(digital_file, changes \\ %{}) do
    DigitalFile.changeset(digital_file, changes)
  end

  def change_project(project, changes \\ %{}) do
    Project.changeset(project, changes)
  end

  def change_format(format, changes \\ %{}) do
    Format.changeset(format, changes)
  end

  def change_author(author, changes \\ %{}) do
    Author.changeset(author, changes)
  end

  def create_author(%{"user_id" => user_id} = params) when user_id not in ["", nil] do
    Multi.new()
    |> Multi.insert(:author, fn _ ->
      new_author()
      |> change_author(params)
    end)
    |> Multi.update_all(
      :user_update,
      fn %{author: author} ->
        from(u in User, where: u.id == ^user_id, update: [set: [author_id: ^author.id]])
      end,
      []
    )
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes[:user_update]}
      {:error, _} = error -> error
    end
  end

  def create_author(params) do
    new_author()
    |> change_author(params)
    |> Repo.insert()
  end

  def update_author(changeset, nil) do
    Multi.new()
    |> Multi.update(:author, changeset)
    |> Multi.update_all(
      :user_update,
      fn %{author: author} ->
        from(u in User, where: u.author_id == ^author.id)
      end,
      set: [author_id: nil]
    )
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes[:author]}
      {:error, _} = error -> error
    end
  end

  def update_author(changeset, user_id) do
    Multi.new()
    |> Multi.update(:author, changeset)
    |> Multi.update_all(
      :unset_user,
      fn %{author: author} ->
        from(u in User, where: u.author_id == ^author.id)
      end,
      set: [author_id: nil]
    )
    |> Multi.update_all(
      :user_update,
      fn %{author: author} ->
        from(u in User, where: u.id == ^user_id, update: [set: [author_id: ^author.id]])
      end,
      []
    )
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes[:author]}
      {:error, _} = error -> error
    end
  end

  def delete_author(author_id) do
    Multi.new()
    |> Multi.update_all(
      :user_update,
      fn _ ->
        from(u in User, where: u.author_id == ^author_id)
      end,
      set: [author_id: nil]
    )
    |> Multi.delete(:author, fn _ -> Repo.get(Author, author_id) end)
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes[:author]}
      {:error, _} = error -> error
    end
  end

  def list_categories do
    from(c in Category, order_by: [asc: c.name])
    |> Repo.all()
  end

  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def list_contents_by_book_id(book_id) do
    from(
      c in Content,
      where: c.book_id == ^book_id,
      order_by: [asc: c.chapter_type, asc: c.order]
    )
    |> Repo.all()
  end

  def list_formats_by_book_id(book_id) do
    from(
      f in Format,
      where: f.book_id == ^book_id,
      order_by: [asc: f.name]
    )
    |> Repo.all()
  end

  def get_format(format_id) do
    Repo.get(Format, format_id)
    |> Repo.preload(:files)
  end

  def get_format_by_book_slug_and_name(book_slug, name) do
    from(f in Format, join: b in assoc(f, :book), where: b.slug == ^book_slug and f.name == ^name)
    |> Repo.one()
  end

  def get_digital_file(id), do: Repo.get!(DigitalFile, id)

  def get_content(id), do: Repo.get!(Content, id)

  def get_project(id), do: Repo.get!(Project, id)

  def new_book do
    %Book{}
  end

  def new_book_shop_link do
    %Book.ShopLink{}
  end

  def new_content(book_id) do
    %Content{book_id: book_id}
  end

  def new_review(book_id) do
    %Review{book_id: book_id}
  end

  def new_cross_selling(book_id) do
    %BookCrossSelling{book_id: book_id}
  end

  def new_digital_file(format_id) do
    %DigitalFile{format_id: format_id}
  end

  def new_project(book_id) do
    %Project{book_id: book_id}
  end

  def new_author do
    Repo.preload(%Author{}, :user)
  end

  def new_book_author(book_id) do
    %BookAuthor{book_id: book_id}
  end

  def new_format(book_id) do
    %Format{book_id: book_id}
  end

  def create_format(attrs) do
    %Format{}
    |> Format.changeset(attrs)
    |> Repo.insert()
  end

  def update_all_contents(content_ids, opts) do
    from(c in Content, where: c.id in ^content_ids)
    |> Repo.update_all(set: opts)
  end

  def delete_all_contents(content_ids) do
    from(c in Content, where: c.id in ^content_ids)
    |> Repo.delete_all()
  end
end
