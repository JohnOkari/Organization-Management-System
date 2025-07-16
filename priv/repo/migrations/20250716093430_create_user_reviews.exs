defmodule OrgManagementSystem.Repo.Migrations.CreateUserReviews do
  use Ecto.Migration

  def change do
    create table(:user_reviews) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :reviewer_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create constraint(:user_reviews, :valid_status, check: "status IN ('invited', 'reviewed', 'approved')")
    create index(:user_reviews, [:status])
    create index(:user_reviews, [:user_id])
    create index(:user_reviews, [:reviewer_id])
  end
end
