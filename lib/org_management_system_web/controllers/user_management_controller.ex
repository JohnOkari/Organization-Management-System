defmodule OrgManagementSystemWeb.UserManagementController do
  use OrgManagementSystemWeb, :controller

  # alias OrgManagementSystem.{Repo, Accounts.User, UserReview}
  # import Ecto.Query
  alias OrgManagementSystem.Accounts


  # POST /api/invite_user
  def invite_user(conn, %{"name" => name, "email" => email, "inviter_id" => inviter_id}) do
    inviter = Accounts.get_user!(inviter_id)
    case Accounts.invite_user(name, email, inviter) do
      {:ok, user} -> json(conn, %{status: "ok", user: user})
      {:error, reason} -> json(conn, %{status: "error", reason: inspect(reason)})
    end
  end

  # GET /api/users_by_stage?stage=invited
  def users_by_stage(conn, %{"stage" => stage}) do
    user = conn.assigns.current_user
    users = Accounts.list_users_by_review_stage(stage, user)
    json(conn, users)
  end

  # POST /api/review_user
  def review_user(conn, %{"user_id" => user_id}) do
    reviewer = conn.assigns.current_user
    # Check permission here if needed
    case Accounts.review_user(user_id, reviewer.id) do
      {:ok, review} -> json(conn, review)
      {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  # POST /api/approve_user
  def approve_user(conn, %{"user_id" => user_id}) do
    approver = conn.assigns.current_user
    # Check permission here if needed
    case Accounts.approve_user(user_id, approver.id) do
      {:ok, review} -> json(conn, review)
      {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  # POST /api/assign_role
  def assign_role(conn, %{"user_id" => user_id, "org_id" => org_id, "role_id" => role_id}) do
    case Accounts.assign_role(user_id, org_id, role_id) do
      %OrgManagementSystem.UserOrganization{} = user_org -> json(conn, %{status: "ok", user_org: user_org})
      {:error, reason} -> json(conn, %{status: "error", reason: inspect(reason)})
    end
  end

  # POST /api/login
  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})

      user ->
        if Accounts.can_user_login?(user) do
          # You can return a token or user info here
          json(conn, %{status: "ok", user: user})
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "User not approved"})
        end
    end
  end
end
