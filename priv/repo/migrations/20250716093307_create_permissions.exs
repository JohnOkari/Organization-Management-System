defmodule OrgManagementSystem.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string
      add :role_id, references(:roles, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:name])
    create index(:permissions, [:role_id])
  end
end
