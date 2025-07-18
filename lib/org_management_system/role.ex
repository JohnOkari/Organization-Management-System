defmodule OrgManagementSystem.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string

    many_to_many :permissions, OrgManagementSystem.Permission, join_through: "roles_permissions"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
