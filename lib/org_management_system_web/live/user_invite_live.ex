# lib/org_management_system_web/live/user_invite_live.ex
defmodule OrgManagementSystemWeb.UserInviteLive do
  use OrgManagementSystemWeb, :live_view

  # alias OrgManagementSystem.{Accounts, UserReview}
  alias OrgManagementSystem.Accounts

  # LiveView for inviting users
  def mount(_params, _session, socket) do
    {:ok, assign(socket, email: "", error: nil)}
  end

  def handle_event("invite", %{"email" => email}, socket) do
    case Accounts.invite_user(email, socket.assigns.current_user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User invited successfully")
         |> assign(email: "")}
      {:error, _} ->
        {:noreply, assign(socket, error: "Invalid email or user already exists")}
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Invite User</h1>
    <form phx-submit="invite">
      <input type="email" name="email" value={@email} placeholder="Enter email" />
      <%= if @error do %>
        <p class="error"><%= @error %></p>
      <% end %>
      <button type="submit">Invite</button>
    </form>
    """
  end
end
