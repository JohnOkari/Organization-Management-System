defmodule OrgManagementSystem.Repo do
  use Ecto.Repo,
    otp_app: :org_management_system,
    adapter: Ecto.Adapters.Postgres
end
