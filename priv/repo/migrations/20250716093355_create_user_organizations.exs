defmodule OrgManagementSystem.Repo.Migrations.CreateUserOrganizations do
  use Ecto.Migration

  def change do
    create table(:user_organizations) do
      add :user_id, references(:users, on_delete: :nothing)
      add :organization_id, references(:organizations, on_delete: :nothing)
      add :role_id, references(:roles, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:user_organizations, [:user_id])
    create index(:user_organizations, [:organization_id])
    create index(:user_organizations, [:role_id])
  end
end
