defmodule OrgManagementSystem.Repo.Migrations.AddCreatedByIdToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :created_by_id, references(:users, on_delete: :nothing)
    end
  end
end
