defmodule OrgManagementSystem.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :created_by_id, :inserted_at, :updated_at]}
  schema "organizations" do
    field :name, :string
    field :created_by_id, :id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
