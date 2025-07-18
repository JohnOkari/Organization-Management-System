defmodule OrgManagementSystem.RolePermission do
  use Ecto.Schema

  @primary_key false
  schema "roles_permissions" do
    belongs_to :role, OrgManagementSystem.Role
    belongs_to :permission, OrgManagementSystem.Permission
  end
end
