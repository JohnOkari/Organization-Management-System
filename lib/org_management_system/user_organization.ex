defmodule OrgManagementSystem.UserOrganization do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :user_id, :organization_id, :role_id, :inserted_at, :updated_at]}
  schema "user_organizations" do

    field :user_id, :id
    field :organization_id, :id
    field :role_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_organization, attrs) do
    user_organization
    |> cast(attrs, [])
    |> validate_required([])
  end
end
