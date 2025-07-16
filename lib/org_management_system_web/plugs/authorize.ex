# lib/org_management_system_web/plugs/authorize.ex
defmodule OrgManagementSystemWeb.Plugs.Authortlandize do
  import Plug.Conn
  import Phoenix.Controller
  alias OrgManagementSystem.Accounts

  def init(permission), do: permission

  def call(conn, permission) do
    user = conn.assigns.current_user
    org_id = conn.params["organization_id"]

    if Accounts.has_permission?(user, org_id, permission) || user.is_superuser do
      conn
    else
      conn
      |> put_flash(:error, "Unauthorized access")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
