defmodule OrgManagementSystem.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :password_hash, :string
    field :is_superuser, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password_hash, :is_superuser])
    |> validate_required([:name, :email, :password_hash, :is_superuser])
    |> unique_constraint(:email)
  end
end
