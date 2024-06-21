defmodule BooksWeb.UserSessionControllerTest do
  use BooksWeb.ConnCase, async: true

  import Books.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Inicia sesión</h1>"
      assert response =~ "Registro</a>"
      assert response =~ "¿Olvidó su contraseña?</a>"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == Routes.user_bookshelf_path(conn, :index)
    end
  end

  describe "POST /users/log_in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == Routes.user_bookshelf_path(conn, :index)

      # Now do a logged in request and assert on the menu
      conn = get(conn, Routes.user_bookshelf_path(conn, :index))
      response = html_response(conn, 200)
      assert response =~ "Estantería"
      assert response =~ "Configuración"
      assert response =~ "Cerrar sesión"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_books_web_user_remember_me"]
      assert redirected_to(conn) == Routes.user_bookshelf_path(conn, :index)
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Inicia sesión</h1>"
      assert response =~ "Email o contraseña no válidos"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == Routes.catalog_path(conn, :index)
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Sesión cerrada correctamente."
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == Routes.catalog_path(conn, :index)
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Sesión cerrada correctamente."
    end
  end
end
