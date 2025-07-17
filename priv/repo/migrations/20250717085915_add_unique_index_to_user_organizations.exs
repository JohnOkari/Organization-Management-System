defmodule OrgManagementSystem.Repo.Migrations.AddUniqueIndexToUserOrganizations do
  use Ecto.Migration

  def change do
    create unique_index(:user_organizations, [:user_id, :organization_id])
  end
end
