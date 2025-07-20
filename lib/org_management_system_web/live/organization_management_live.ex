defmodule OrgManagementSystemWeb.OrganizationManagementLive do
  use OrgManagementSystemWeb, :live_view

  alias OrgManagementSystem.Accounts
  alias OrgManagementSystem.Organization

  def mount(_params, _session, socket) do
    organizations = Accounts.list_organizations()
    {:ok, assign(socket, organizations: organizations, selected_org: nil, org_changeset: Organization.changeset(%Organization{}, %{}), users: [])}
  end

  def handle_event("select_org", %{"org-id" => org_id}, socket) do
    org = Enum.find(socket.assigns.organizations, &Integer.to_string(&1.id) == org_id)
    users = Accounts.list_organization_users(org.id)
    {:noreply, assign(socket, selected_org: org, users: users)}
  end
  
  def handle_event("create_org", %{"organization" => org_params}, socket) do
    current_user = socket.assigns[:current_user]
    case Accounts.create_organization(org_params, current_user) do
      {:ok, _org} ->
        organizations = Accounts.list_organizations()
        {:noreply, assign(socket, organizations: organizations, org_changeset: Organization.changeset(%Organization{}, %{})) |> put_flash(:info, "Organization created!")}
      {:error, changeset} ->
        {:noreply, assign(socket, org_changeset: changeset) |> put_flash(:error, "Failed to create organization.")}
    end
  end

  def handle_event("edit_org", %{"org-id" => org_id}, socket) do
    org = Enum.find(socket.assigns.organizations, &Integer.to_string(&1.id) == org_id)
    changeset = Organization.changeset(org, %{})
    {:noreply, assign(socket, selected_org: org, org_changeset: changeset)}
  end

  def handle_event("update_org", %{"organization" => org_params}, socket) do
    org = socket.assigns.selected_org
    case Accounts.update_organization(org, org_params) do
      {:ok, updated_org} ->
        organizations = Accounts.list_organizations()
        {:noreply, assign(socket, organizations: organizations, selected_org: updated_org, org_changeset: Organization.changeset(updated_org, %{})) |> put_flash(:info, "Organization updated!")}
      {:error, changeset} ->
        {:noreply, assign(socket, org_changeset: changeset) |> put_flash(:error, "Failed to update organization.")}
    end
  end
end
