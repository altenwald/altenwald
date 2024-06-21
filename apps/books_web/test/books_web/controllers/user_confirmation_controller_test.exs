defmodule BooksWeb.UserConfirmationControllerTest do
  use BooksWeb.ConnCase, async: true

  alias Books.Accounts
  alias Books.Repo
  import Books.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.user_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<p class=\"help\">Reenviar instrucciones de confirmación</p>"
    end
  end

  describe "POST /users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Si tu email está en nuestro sistema"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "does not send confirmation token if User is confirmed", %{conn: conn, user: user} do
      Repo.update!(Accounts.User.confirm_changeset(user))

      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Si tu email está en nuestro sistema"
      refute Repo.get_by(Accounts.UserToken, user_id: user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Si tu email está en nuestro sistema"
      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.user_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirmar cuenta</h1>"

      form_action = Routes.user_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url, "en")
        end)

      conn = post(conn, Routes.user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) =~ "/reset-password/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Usuario confirmado correctamente. Necesitas indicar una contraseña."

      assert Accounts.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      # assert Repo.all(Accounts.UserToken) == []

      # When not logged in
      conn = post(conn, Routes.user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "El enlace de confirmación de usuario no es válido o expiró."

      # When logged in
      conn =
        build_conn()
        |> log_in_user(user)
        |> post(Routes.user_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn = post(conn, Routes.user_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "El enlace de confirmación de usuario no es válido o expiró."

      refute Accounts.get_user!(user.id).confirmed_at
    end
  end
end
