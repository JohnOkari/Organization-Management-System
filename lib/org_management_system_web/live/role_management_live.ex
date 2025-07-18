defmodule OrgManagementSystemWeb.RoleManagementLive do
  use OrgManagementSystemWeb, :live_view

  alias OrgManagementSystem.Accounts

  def mount(_params, _session, socket) do
    roles = Accounts.list_roles()
    permissions = Accounts.list_permissions()
    users = Accounts.list_users()
    organizations = Accounts.list_organizations()
    {:ok, assign(socket, roles: roles, permissions: permissions, users: users, organizations: organizations)}
  end

  def handle_event("add_permission", %{"role-id" => role_id, "permission-name" => permission_name}, socket) do
    Accounts.add_permission_to_role(permission_name, role_id)
    {:noreply, put_flash(socket, :info, "Permission added!")}
  end

  def handle_event("assign_user_role", %{"user-id" => user_id, "org-id" => org_id, "role-id" => role_id}, socket) do
    IO.inspect({user_id, org_id, role_id}, label: "Assigning role")
    Accounts.assign_role(user_id, org_id, role_id)
    {:noreply, put_flash(socket, :info, "Role assigned to user!")}
  end
end
