defmodule OrgManagementSystemWeb.RoleManagementLive do
  use OrgManagementSystemWeb, :live_view

  alias OrgManagementSystem.Accounts

  def mount(_params, _session, socket) do
    roles = Accounts.list_roles()
    permissions = Accounts.list_permissions()
    {:ok, assign(socket, roles: roles, permissions: permissions)}
  end

  def handle_event("add_permission", %{"role-id" => role_id, "permission-name" => permission_name}, socket) do
    Accounts.add_permission_to_role(permission_name, role_id)
    {:noreply, put_flash(socket, :info, "Permission added!")}
  end

  # ... more events for create/edit/delete roles
end
