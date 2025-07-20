defmodule OrgManagementSystemWeb.UserSessionController do
  use OrgManagementSystemWeb, :controller

  alias OrgManagementSystem.Accounts
  alias OrgManagementSystemWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, _msg) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      # Check if user is approved
      review = OrgManagementSystem.Repo.get_by(OrgManagementSystem.UserReview, user_id: user.id)
      if review && review.status == "approved" do
        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:user_return_to, "/admin/users")
        |> UserAuth.log_in_user(user, user_params)
      else
        conn
        |> put_flash(:error, "Your account is not approved yet.")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/log_in")
      end
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
