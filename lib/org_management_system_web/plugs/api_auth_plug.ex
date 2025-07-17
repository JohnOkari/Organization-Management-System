# lib/org_management_system_web/plugs/api_auth_plug.ex
defmodule OrgManagementSystemWeb.ApiAuthPlug do
  import Plug.Conn
  import Phoenix.Controller
  alias OrgManagementSystem.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    # Example: get user_id from header (for demo only, use real auth in production!)
    user_id = get_req_header(conn, "x-user-id") |> List.first()
    user = user_id && Accounts.get_user!(user_id)
    if user do
      assign(conn, :current_user, user)
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
      |> halt()
    end
  end
end
