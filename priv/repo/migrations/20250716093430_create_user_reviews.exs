defmodule OrgManagementSystem.Repo.Migrations.CreateUserReviews do
  use Ecto.Migration

  def change do
    create table(:user_reviews) do
      add :status, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :reviewer_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:user_reviews, [:user_id])
    create index(:user_reviews, [:reviewer_id])
  end
end
