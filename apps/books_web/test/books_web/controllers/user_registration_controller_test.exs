defmodule BooksWeb.UserRegistrationControllerTest do
  use BooksWeb.ConnCase, async: true

  import Books.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Registro</h1>"
      assert response =~ "Inicia sesión</a>"
      assert response =~ "¿Olvidó su contraseña?</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == Routes.user_bookshelf_path(conn, :index)
    end
  end

  # TODO: it isn't active at the moment.
  # describe "POST /users/register" do
  #   @tag :capture_log
  #   test "creates account and logs the user in", %{conn: conn} do
  #     email = unique_user_email()

  #     conn =
  #       post(conn, Routes.user_registration_path(conn, :create), %{
  #         "user" => valid_user_attributes(email: email)
  #       })

  #     assert get_session(conn, :user_token)
  #     assert redirected_to(conn) == "/"

  #     # Now do a logged in request and assert on the menu
  #     conn = get(conn, "/")
  #     response = html_response(conn, 200)
  #     assert response =~ email
  #     assert response =~ "Settings</a>"
  #     assert response =~ "Log out</a>"
  #   end

  #   test "render errors for invalid data", %{conn: conn} do
  #     conn =
  #       post(conn, Routes.user_registration_path(conn, :create), %{
  #         "user" => %{"email" => "with spaces", "password" => "too short"}
  #       })

  #     response = html_response(conn, 200)
  #     assert response =~ "<h1>Register</h1>"
  #     assert response =~ "must have the @ sign and no spaces"
  #     assert response =~ "should be at least 12 character"
  #   end
  # end
end
