defmodule Books.Posts.CommentNotifier do
  import Swoosh.Email

  alias Books.Mailer

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

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_new_comment(user, post, url, "en") do
    deliver(user.email, "[Altenwald] New comment: #{post.title}", """
    Hi!

    You have a notification, a new comment arrived to the post #{post.title}:

    #{url}

    You are receiving this email because you belongs to the Altenwald Community. This account will let you access to your bought books and much more. If you want to know more about the community check the website and check the settings in the configuration section.

    Kind regards,
    Altenwald team.
    """)
  end

  def deliver_new_comment(user, post, url, "es") do
    deliver(user.email, "[Altenwald] Nuevo comentario: #{post.title}", """
    ¡Hola!

    Tienes una notificación, un nuevo comentario para el artículo #{post.title}:

    #{url}

    Recibes este email porque perteneces a la Comunidad Altenwald. Esta cuenta te permite acceder a tus libros comprados y mucho más. Si quieres saber más acerca de la comunidad comprueba el sitio web y echa un vistazo a la sección de configuración.

    Saludos,
    El equipo de Altenwald.
    """)
  end
end
