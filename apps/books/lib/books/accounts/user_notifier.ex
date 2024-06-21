defmodule Books.Accounts.UserNotifier do
  import Swoosh.Email

  alias Books.{Catalog, Mailer}

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from(Application.get_env(:books, :email_from))
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp greets("en") do
    "Hi!"
  end

  defp greets("es") do
    "¡Hola!"
  end

  defp closing("en") do
    """
    Kind regards,
    Altenwald team.
    """
  end

  defp closing("es") do
    """
    Saludos,
    El equipo de Altenwald.
    """
  end

  @doc """
  Deliver an upgrade notification about a book for a user.
  """
  def deliver_book_upgrade(user, book, "en" = locale) do
    title = Catalog.get_full_book_title(book)

    deliver(user.email, "[Altenwald] Upgraded book: #{title}", """
    #{greets(locale)}

    You have available a new file for the book:

    #{title}.

    #{closing(locale)}
    """)
  end

  def deliver_book_upgrade(user, book, "es" = locale) do
    title = Catalog.get_full_book_title(book)

    deliver(user.email, "[Altenwald] Libro actualizado: #{title}", """
    #{greets(locale)}

    Tienes disponible un nuevo fichero para el libro:

    #{title}.

    #{closing(locale)}
    """)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url, "en" = locale) do
    deliver(user.email, "Welcome to Altenwald", """
    #{greets(locale)}

    Welcome to the Altenwald Community, you can confirm your account by visiting the URL below:

    #{url}

    You are receiving this email because you bought a book from Altenwald. This account will let you access to your bought books and much more. If you want to know more about the community check the website.

    #{closing(locale)}
    """)
  end

  def deliver_confirmation_instructions(user, url, "es" = locale) do
    deliver(user.email, "Bienvenido a Altenwald", """
    #{greets(locale)}

    Bienvenido a la Comunidad Altenwald, puedes confirmar tu cuenta visitando la siguiente URL:

    #{url}

    Estás reciviendo este email porque compraste un libro en Altenwald. Esta cuenta te permitirá acceder a tus libros comprados en cualquier momento y mucho más. Si quieres saber más acerca de la comunidad echa un vistazo al sitio web.

    #{closing(locale)}
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url, "en" = locale) do
    deliver(user.email, "Reset password instructions", """
    #{greets(locale)}

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    #{closing(locale)}
    """)
  end

  def deliver_reset_password_instructions(user, url, "es" = locale) do
    deliver(user.email, "Instrucciones para recuperar constraseña", """
    #{greets(locale)}

    Puedes recuperar tu contraseña siguiendo el siguiente enlace:

    #{url}

    Si no hiciste la solicitud de cambio, ignora este mensaje.

    #{closing(locale)}
    """)
  end
end
