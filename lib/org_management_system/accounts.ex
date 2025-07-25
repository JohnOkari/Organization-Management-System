defmodule OrgManagementSystem.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias OrgManagementSystem.Repo

  alias OrgManagementSystem.Accounts.{User, UserToken, UserNotifier}
  alias OrgManagementSystem.UserReview
  alias OrgManagementSystem.Organization
  alias OrgManagementSystem.UserOrganization
  alias OrgManagementSystem.Role
  alias OrgManagementSystem.Permission

  ## Database getters


  def authenticate_user(email, password) do
    with {:ok, user} <- get_user_by_email(email),
         :ok <- verify_password(user, password),
         {:ok, review} <- get_user_review(user),
         true <- review.status == "approved" do
      {:ok, user}
    else
      _ -> {:error, :unauthorized}
    end
  end

  defp verify_password(%User{} = user, password) do
    if User.valid_password?(user, password), do: :ok, else: {:error, :invalid_password}
  end

  defp get_user_review(_user), do: {:ok, %{status: "approved"}}


  def has_permission?(user, org_id, permission_name) do
    cond do
      user.is_superuser -> true
      is_nil(org_id) -> false
      true ->
        from(uo in OrgManagementSystem.UserOrganization,
          join: r in Role, on: uo.role_id == r.id,
          join: rp in OrgManagementSystem.RolePermission, on: rp.role_id == r.id,
          join: p in Permission, on: p.id == rp.permission_id,
          where: uo.user_id == ^user.id and uo.organization_id == ^org_id and p.name == ^permission_name
        )
        |> Repo.exists?()
    end
  end

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  defp generate_random_password(length \\ 12) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end

  def invite_user(name, email, inviter) do
    Repo.transaction(fn ->
      password = generate_random_password()
      user =
        Repo.get_by(User, email: email) ||
          %User{name: name, email: email}
          |> User.registration_changeset(%{password: password, password_confirmation: password})
          |> Repo.insert!()

      %UserReview{user_id: user.id, status: "invited", reviewer_id: inviter.id}
      |> Repo.insert!()

      # Send invite email with password
      OrgManagementSystem.Accounts.UserNotifier.deliver_invite_email(email, name, password)

      user
    end)
  end

  # def approve_user(user_id, reviewer_id) do
  #   review = Repo.get_by!(UserReview, user_id: user_id)
  #   review
  #   |> Ecto.Changeset.change(status: "approved", reviewer_id: reviewer_id)
  #   |> Repo.update()
  # end

  def assign_role(user_id, org_id, role_id) do
    attrs = %{user_id: user_id, organization_id: org_id, role_id: role_id}
    Repo.insert!(%OrgManagementSystem.UserOrganization{} |> Ecto.Changeset.change(attrs), on_conflict: :replace_all, conflict_target: [:user_id, :organization_id])
  end

  def list_user_organizations(user) do
    from(o in Organization,
      join: uo in UserOrganization, on: uo.organization_id == o.id,
      where: uo.user_id == ^user.id,
      select: o
    ) |> Repo.all()
  end

  def create_organization(attrs, creator_user) do
    attrs = Map.put(attrs, "created_by_id", creator_user.id)
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  def update_organization(org, attrs) do
    org
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  def grant_role(user_id, org_id, role_id, granter_user) do
    IO.inspect({:grant_role_called, user_id, org_id, role_id, granter_user}, label: "DEBUG grant_role")
    if has_permission?(granter_user, org_id, "grant_role") do
      case Repo.get_by(UserOrganization, user_id: user_id, organization_id: org_id) do
        nil ->
          # Insert new
          attrs = %{user_id: user_id, organization_id: org_id, role_id: role_id}
          Repo.insert(%UserOrganization{} |> Ecto.Changeset.change(attrs))
        user_org ->
          # Update existing
          user_org
          |> Ecto.Changeset.change(role_id: role_id)
          |> Repo.update()
      end
    else
      {:error, :unauthorized}
    end
  end

  def list_organization_users(org_id) do
    from(u in User,
      join: uo in UserOrganization, on: uo.user_id == u.id,
      join: r in Role, on: uo.role_id == r.id,
      where: uo.organization_id == ^org_id,
      select: %{user: u, role_id: uo.role_id, role_name: r.name}
    ) |> Repo.all()
  end

  def user_in_organization?(%User{id: user_id}, org_id) do
    Repo.exists?(
      from uo in UserOrganization,
        where: uo.user_id == ^user_id and uo.organization_id == ^org_id
    )
  end

  def list_users_by_review_stage(stage, current_user) do
    permission =
      case stage do
        "invited" -> "view_invited_users"
        "reviewed" -> "review_reviewed_users"
        "approved" -> "view_approved_users"
        _ -> nil
      end

    if (permission && has_permission?(current_user, nil, permission)) or current_user.is_superuser do
      import Ecto.Query
      from(u in User,
        join: ur in UserReview, on: ur.user_id == u.id,
        where: ur.status == ^stage,
        select: %{user: u, review: ur}
      ) |> Repo.all()
    else
      []
    end
  end

  def can_user_login?(user) do
    review = Repo.get_by(UserReview, user_id: user.id)
    review && review.status == "approved"
  end

  def review_user(user_id, reviewer_id) do
    review = Repo.get_by!(UserReview, user_id: user_id)
    review
    |> Ecto.Changeset.change(status: "reviewed", reviewer_id: reviewer_id)
    |> Repo.update()
  end

  def approve_user(user_id, approver_id) do
    review = Repo.get_by!(UserReview, user_id: user_id)
    review
    |> Ecto.Changeset.change(status: "approved", reviewer_id: approver_id)
    |> Repo.update()
  end

  @doc """
  Add a permission to a role (many-to-many).

  ## Examples

      iex> add_permission_to_role("edit_organization", role_id)
      {:ok, %OrgManagementSystem.RolePermission{}}

      iex> add_permission_to_role("invalid_permission", role_id)
      {:error, %Ecto.Changeset{}}
  """
  def add_permission_to_role(permission_name, role_id) do
    role_id = if is_binary(role_id), do: String.to_integer(role_id), else: role_id
    Repo.transaction(fn ->
      # Find or create the permission
      permission =
        case Repo.get_by(Permission, name: permission_name) do
          nil ->
            %Permission{}
            |> Permission.changeset(%{name: permission_name})
            |> Repo.insert!()
          perm -> perm
        end

      # Insert into join table
      %OrgManagementSystem.RolePermission{}
      |> Ecto.Changeset.change(%{role_id: role_id, permission_id: permission.id})
      |> Repo.insert(on_conflict: :nothing)
    end)
    |> case do
      {:ok, {:ok, role_permission}} -> {:ok, role_permission}
      {:ok, role_permission} -> {:ok, role_permission}
      {:error, _failed_op, changeset, _} -> {:error, changeset}
    end
  end

  def add_permission_to_role_by_id(permission_id, role_id) do
    OrgManagementSystem.Repo.insert(
      %OrgManagementSystem.RolePermission{}
      |> Ecto.Changeset.change(%{role_id: role_id, permission_id: permission_id}),
      on_conflict: :nothing
    )
  end

  def list_permissions_for_role(role_id) do
    from(p in OrgManagementSystem.Permission,
      join: rp in OrgManagementSystem.RolePermission, on: rp.permission_id == p.id,
      where: rp.role_id == ^role_id,
      select: p
    )
    |> OrgManagementSystem.Repo.all()
  end

  def remove_permission_from_role(permission_id, role_id) do
    OrgManagementSystem.Repo.delete_all(
      from rp in OrgManagementSystem.RolePermission,
        where: rp.role_id == ^role_id and rp.permission_id == ^permission_id
    )
  end

  def list_users do
    OrgManagementSystem.Repo.all(OrgManagementSystem.Accounts.User)
  end

  def list_roles do
    OrgManagementSystem.Repo.all(OrgManagementSystem.Role)
  end

  def list_permissions do
    OrgManagementSystem.Repo.all(OrgManagementSystem.Permission)
  end

  def list_organizations do
    OrgManagementSystem.Repo.all(OrgManagementSystem.Organization)
  end

  def list_users_with_review_status do
    from(u in OrgManagementSystem.Accounts.User,
      left_join: ur in OrgManagementSystem.UserReview, on: ur.user_id == u.id,
      select: %{user: u, review_status: ur.status}
    )
    |> OrgManagementSystem.Repo.all()
  end
end
