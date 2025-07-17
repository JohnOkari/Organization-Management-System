defmodule OrgManagementSystemWeb.OrganizationController do
  use OrgManagementSystemWeb, :controller
  alias OrgManagementSystem.{Repo, Accounts, Organization}

  # GET /api/organizations
  def index(conn, _params) do
    user = conn.assigns.current_user
    orgs = Accounts.list_user_organizations(user)
    json(conn, orgs)
  end

  # GET /api/organizations/:id
  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    if Accounts.user_in_organization?(user, id) or user.is_superuser do
      org = Repo.get!(Organization, id)
      json(conn, org)
    else
      conn |> put_status(:forbidden) |> json(%{error: "Access denied"})
    end
  end

  # POST /api/organizations
  def create(conn, %{"name" => name}) do
    user = conn.assigns.current_user
    case Accounts.create_organization(%{name: name}, user) do
      {:ok, org} -> json(conn, org)
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: changeset})
    end
  end

  # PUT /api/organizations/:id
  def update(conn, %{"id" => id, "name" => name}) do
    user = conn.assigns.current_user
    org = Repo.get!(Organization, id)
    if Accounts.has_permission?(user, id, "edit_organization") or user.is_superuser do
      case Accounts.update_organization(org, %{name: name}) do
        {:ok, org} -> json(conn, org)
        {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: changeset})
      end
    else
      conn |> put_status(:forbidden) |> json(%{error: "Access denied"})
    end
  end

  # DELETE /api/organizations/:id
  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    org = Repo.get!(Organization, id)
    if Accounts.has_permission?(user, id, "edit_organization") or user.is_superuser do
      Repo.delete!(org)
      json(conn, %{status: "deleted"})
    else
      conn |> put_status(:forbidden) |> json(%{error: "Access denied"})
    end
  end
end
