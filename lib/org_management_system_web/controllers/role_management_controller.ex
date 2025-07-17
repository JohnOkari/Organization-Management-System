defmodule OrgManagementSystemWeb.RoleManagementController do
  use OrgManagementSystemWeb, :controller
  alias OrgManagementSystem.Accounts

  # POST /api/organizations/:org_id/assign_role
  def assign_role(conn, %{"org_id" => org_id, "user_id" => user_id, "role_id" => role_id}) do
    granter = conn.assigns.current_user
    case Accounts.grant_role(user_id, org_id, role_id, granter) do
      {:ok, user_org} -> json(conn, user_org)
      {:error, :unauthorized} -> conn |> put_status(:forbidden) |> json(%{error: "Access denied"})
      {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  # GET /api/organizations/:org_id/users
  def list_org_users(conn, %{"org_id" => org_id}) do
    user = conn.assigns.current_user
    if Accounts.user_in_organization?(user, org_id) or user.is_superuser do
      users = Accounts.list_organization_users(org_id)
      json(conn, users)
    else
      conn |> put_status(:forbidden) |> json(%{error: "Access denied"})
    end
  end
end
