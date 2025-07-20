defmodule OrgManagementSystemWeb.RoleManagementLive do
  use OrgManagementSystemWeb, :live_view
  on_mount OrgManagementSystemWeb.UserAuth

  alias OrgManagementSystem.Accounts

  def mount(_params, _session, socket) do
    roles = Accounts.list_roles()
    permissions = Accounts.list_permissions()
    users = Accounts.list_users()
    organizations = Accounts.list_organizations()
    current_user = socket.assigns[:current_user]
    {:ok, assign(socket, roles: roles, permissions: permissions, users: users, organizations: organizations, current_user: current_user)}
  end

  def handle_event("add_permission", %{"role-id" => role_id, "permission-name" => permission_name}, socket) do
    Accounts.add_permission_to_role(permission_name, role_id)
    {:noreply, put_flash(socket, :info, "Permission added!")}
  end

  def handle_event("assign_user_role", %{"user-id" => user_id, "org-id" => org_id, "role-id" => role_id}, socket) do
    granter_user = socket.assigns.current_user
    # Convert IDs to integers
    user_id = String.to_integer(user_id)
    org_id = String.to_integer(org_id)
    role_id = String.to_integer(role_id)
    case Accounts.grant_role(user_id, org_id, role_id, granter_user) do
      {:ok, _user_org} ->
        {:noreply, put_flash(socket, :info, "Role assigned to user!")}
      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You do not have permission to assign roles.")}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to assign role.")}
    end
  end
end
