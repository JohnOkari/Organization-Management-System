defmodule OrgManagementSystemWeb.RoleManagementLive do
  use OrgManagementSystemWeb, :live_view
  on_mount OrgManagementSystemWeb.UserAuth

  alias OrgManagementSystem.Accounts

  defp available_permissions_for_role(all_permissions, assigned_permissions) do
    assigned_ids = MapSet.new(Enum.map(assigned_permissions, & &1.id))
    Enum.filter(all_permissions, fn perm -> not MapSet.member?(assigned_ids, perm.id) end)
  end

  def mount(_params, _session, socket) do
    roles = Accounts.list_roles()
    permissions = Accounts.list_permissions()
    users = Accounts.list_users()
    organizations = Accounts.list_organizations()
    current_user = socket.assigns[:current_user]
    role_permissions = for role <- roles, into: %{} do
      {role.id, Accounts.list_permissions_for_role(role.id)}
    end
    available_permissions = for role <- roles, into: %{} do
      {role.id, available_permissions_for_role(permissions, role_permissions[role.id] || [])}
    end
    {:ok, assign(socket, roles: roles, permissions: permissions, users: users, organizations: organizations, current_user: current_user, role_permissions: role_permissions, available_permissions: available_permissions)}
  end

  def handle_event("add_permission", %{"role-id" => role_id, "permission-id" => permission_id}, socket) do
    role_id = String.to_integer(role_id)
    permission_id = String.to_integer(permission_id)
    Accounts.add_permission_to_role_by_id(permission_id, role_id)
    roles = Accounts.list_roles()
    permissions = Accounts.list_permissions()
    role_permissions = for role <- roles, into: %{} do
      {role.id, Accounts.list_permissions_for_role(role.id)}
    end
    available_permissions = for role <- roles, into: %{} do
      {role.id, available_permissions_for_role(permissions, role_permissions[role.id] || [])}
    end
    {:noreply, assign(socket, roles: roles, permissions: permissions, role_permissions: role_permissions, available_permissions: available_permissions) |> put_flash(:info, "Permission added!")}
  end

  def handle_event("remove_permission", %{"role-id" => role_id, "permission-id" => permission_id}, socket) do
    role_id = String.to_integer(role_id)
    permission_id = String.to_integer(permission_id)
    Accounts.remove_permission_from_role(permission_id, role_id)
    roles = Accounts.list_roles()
    permissions = Accounts.list_permissions()
    role_permissions = for role <- roles, into: %{} do
      {role.id, Accounts.list_permissions_for_role(role.id)}
    end
    available_permissions = for role <- roles, into: %{} do
      {role.id, available_permissions_for_role(permissions, role_permissions[role.id] || [])}
    end
    {:noreply, assign(socket, roles: roles, permissions: permissions, role_permissions: role_permissions, available_permissions: available_permissions)}
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
