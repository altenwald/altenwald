defmodule BooksWeb.UserSettingsControllerTest do
  use BooksWeb.ConnCase, async: true

  import Books.AccountsFixtures
  import Tesla.Mock

  alias Books.Accounts

  setup :register_and_log_in_user

  setup do
    mock_global(fn
      # mailchimp
      %{
        method: :get,
        url: "https://us6.api.mailchimp.com/3.0/lists/44ad6e0310/members/" <> _member,
        query: [fields: "marketing_permissions"]
      } ->
        json(%{"marketing_permissions" => []})
    end)

    :ok
  end

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_edit_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ ">Configuración</h1>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_edit_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "PUT /users/settings (change password form)" do
    @tag :broken
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.user_settings_edit_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.user_settings_edit_path(conn, :edit)
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Contraseña actualizada correctamente."

      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    @tag :broken
    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_edit_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ ">Configuración</h1>"
      assert response =~ "deben ser al menos 12 caracteres"
      assert response =~ "no coincide la contraseña"
      assert response =~ "no es válido"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :unimplemented
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, Routes.user_settings_edit_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == Routes.user_settings_edit_path(conn, :edit)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    @tag :unimplemented
    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_edit_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end
end
