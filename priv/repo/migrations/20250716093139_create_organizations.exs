defmodule OrgManagementSystem.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
