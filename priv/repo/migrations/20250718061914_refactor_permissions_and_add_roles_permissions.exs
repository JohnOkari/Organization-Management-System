defmodule OrgManagementSystem.Repo.Migrations.RefactorPermissionsAndAddRolesPermissions do
  use Ecto.Migration

  def change do
    # Remove role_id from permissions
    alter table(:permissions) do
      remove :role_id
    end

    # Create join table for roles and permissions
    create table(:roles_permissions, primary_key: false) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
    end

    create unique_index(:roles_permissions, [:role_id, :permission_id])
  end
end
