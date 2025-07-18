defmodule OrgManagementSystemWeb.Router do
  use OrgManagementSystemWeb, :router

  import OrgManagementSystemWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OrgManagementSystemWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug OrgManagementSystemWeb.ApiAuthPlug
  end

  scope "/", OrgManagementSystemWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", OrgManagementSystemWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:org_management_system, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OrgManagementSystemWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", OrgManagementSystemWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{OrgManagementSystemWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", OrgManagementSystemWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{OrgManagementSystemWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", OrgManagementSystemWeb do
    pipe_through [:browser]


    live_session :authenticated, on_mount: [{OrgManagementSystemWeb.UserAuth, :ensure_authenticated}] do
      live "/admin/users", UserManagementLive
      live "/admin/roles", RoleManagementLive
      # ...other admin LiveViews
    end

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{OrgManagementSystemWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/api", OrgManagementSystemWeb do
    pipe_through :api

    # User management
    post "/invite_user", UserManagementController, :invite_user
    post "/approve_user", UserManagementController, :approve_user
    post "/assign_role", UserManagementController, :assign_role
    get "/users_by_stage", UserManagementController, :users_by_stage
    post "/review_user", UserManagementController, :review_user
    post "/login", UserManagementController, :login

    # Organization CRUD
    get "/organizations", OrganizationController, :index
    get "/organizations/:id", OrganizationController, :show
    post "/organizations", OrganizationController, :create
    put "/organizations/:id", OrganizationController, :update
    delete "/organizations/:id", OrganizationController, :delete

    # Role management
    post "/organizations/:org_id/assign_role", RoleManagementController, :assign_role
    get "/organizations/:org_id/users", RoleManagementController, :list_org_users
    post "/roles/:role_id/permissions", RoleManagementController, :add_permission


  end
end
