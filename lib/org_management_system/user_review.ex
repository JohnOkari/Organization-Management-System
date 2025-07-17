defmodule OrgManagementSystem.UserReview do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :status, :user_id, :reviewer_id, :inserted_at, :updated_at]}
  schema "user_reviews" do
    field :status, :string
    field :user_id, :id
    field :reviewer_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_review, attrs) do
    user_review
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
