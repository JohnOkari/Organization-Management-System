defmodule OrgManagementSystem.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string

    many_to_many :roles, OrgManagementSystem.Role, join_through: "roles_permissions"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
