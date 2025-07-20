defmodule OrgManagementSystemWeb.UserManagementLive do
  use OrgManagementSystemWeb, :live_view

  on_mount OrgManagementSystemWeb.UserAuth
  alias OrgManagementSystem.Accounts

  def mount(_params, _session, socket) do
    users = Accounts.list_users_with_review_status()
    roles = Accounts.list_roles()
    current_user = socket.assigns[:current_user] # This will be set by on_mount
    {:ok, assign(socket, users: users, roles: roles, selected_user: nil, current_user: current_user)}
  end

  def handle_event("select_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    {:noreply, assign(socket, selected_user: user)}
  end

  def handle_event("assign_role", %{"user-id" => user_id, "role-id" => role_id, "org-id" => org_id}, socket) do
    granter_user = socket.assigns.current_user
    Accounts.grant_role(user_id, org_id, role_id, granter_user)
    {:noreply, put_flash(socket, :info, "Role assigned!")}
  end

  def handle_event("invite_user", %{"name" => name, "email" => email}, socket) do
    inviter = socket.assigns.current_user # Make sure you assign this in mount/3
    case Accounts.invite_user(name, email, inviter) do
      {:ok, _user} ->
        users = Accounts.list_users()
        {:noreply, assign(socket, users: users) |> put_flash(:info, "User invited!")}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to invite user: #{inspect(reason)}")}
    end
  end

  def handle_event("review_user", %{"user-id" => user_id}, socket) do
    reviewer = socket.assigns.current_user
    case Accounts.review_user(user_id, reviewer.id) do
      {:ok, _review} ->
        users = Accounts.list_users_with_review_status()
        {:noreply, assign(socket, users: users) |> put_flash(:info, "User reviewed!")}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to review user: #{inspect(reason)}")}
    end
  end

  def handle_event("approve_user", %{"user-id" => user_id}, socket) do
    approver = socket.assigns.current_user
    case Accounts.approve_user(user_id, approver.id) do
      {:ok, _review} ->
        users = Accounts.list_users_with_review_status()
        {:noreply, assign(socket, users: users) |> put_flash(:info, "User approved!")}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to approve user: #{inspect(reason)}")}
    end
  end

  # ... more events for invite, edit, etc.
end
