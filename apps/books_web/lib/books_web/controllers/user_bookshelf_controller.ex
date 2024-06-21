defmodule BooksWeb.UserBookshelfController do
  use BooksWeb, :controller
  require Logger

  def index(conn, _params) do
    user = conn.assigns.current_user

    render(conn, "index.html",
      bookshelf: Books.Accounts.get_bookshelf_by_user(user),
      title: gettext("My Bookshelf")
    )
  end

  def get_existent_filename(nil), do: nil

  def get_existent_filename(file) do
    file_path =
      Application.get_env(:books_web, :files_path)
      |> Path.join(file.filename)

    if File.exists?(file_path) do
      file_path
    end
  end

  def download(conn, %{"file_id" => file_id}) do
    user = conn.assigns.current_user

    Books.Accounts.get_bookshelf_by_user(user)
    |> Stream.flat_map(& &1.book.formats)
    |> Stream.filter(&(&1.files != []))
    |> Stream.flat_map(& &1.files)
    |> Enum.find(&(&1.id == file_id))
    |> get_existent_filename()
    |> case do
      nil ->
        Logger.error("download file #{file_id} for user #{user.email} wasn't found")
        raise BooksWeb.ErrorNotFound, message: gettext("file not found")

      filename ->
        basename = Path.basename(filename)

        conn
        |> put_resp_content_type("application/octet-stream", "utf-8")
        |> put_resp_header(
          "content-disposition",
          ~s[attachment; filename="#{basename}"]
        )
        |> send_file(200, filename)
    end
  end
end
