alias OrgManagementSystem.Repo
alias OrgManagementSystem.{User, Role, Permission}

# Create superuser
Repo.insert!(%User{
  name: "Super Admin",
  email: "superadmin@example.com",
  password_hash: Bcrypt.hash_pwd_salt("supersecurepassword"),
  is_superuser: true
})

# Create roles
admin_role = Repo.insert!(%Role{name: "Admin"})
reviewer_role = Repo.insert!(%Role{name: "Reviewer"})
approver_role = Repo.insert!(%Role{name: "Approver"})
_member_role = Repo.insert!(%Role{name: "Member"})

# Create permissions
Repo.insert!(%Permission{name: "edit_organization", role_id: admin_role.id})
Repo.insert!(%Permission{name: "grant_roles", role_id: admin_role.id})
Repo.insert!(%Permission{name: "view_invited_users", role_id: reviewer_role.id})

# Create organization
_acme_org = Repo.insert!(%OrgManagementSystem.Organization{name: "Acme Corp"})
