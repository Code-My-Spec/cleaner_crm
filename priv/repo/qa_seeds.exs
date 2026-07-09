# QA seed script — idempotent. Run with: mix run priv/repo/qa_seeds.exs
#
# Creates two confirmed users with passwords (an owner and a cleaner) and
# one account (the cleaning company) owned by the owner. Prints credentials.

alias CleanerCrm.{Users, Accounts}
alias CleanerCrm.Users.Scope

qa_password = "qa password 1234"

ensure_user = fn email ->
  case Users.get_user_by_email(email) do
    nil ->
      {:ok, user} = Users.register_user(%{email: email})

      # Confirm via the magic-link flow (same path a real user takes).
      {:ok, email_struct} = Users.deliver_login_instructions(user, &"[TOKEN]#{&1}[TOKEN]")
      [_, token | _] = String.split(email_struct.text_body, "[TOKEN]")
      {:ok, {user, _expired}} = Users.login_user_by_magic_link(token)

      {:ok, {user, _expired}} = Users.update_user_password(user, %{password: qa_password})
      user

    user ->
      user
  end
end

owner = ensure_user.("qa-owner@cleanercrm.test")
cleaner = ensure_user.("qa-cleaner@cleanercrm.test")

owner_scope = Scope.for_user(owner)

account =
  case Accounts.list_accounts(owner_scope) do
    [account | _] ->
      account

    [] ->
      {:ok, account} = Accounts.create_account(owner_scope, %{name: "QA Sparkle Cleaning Co"})
      account
  end

# The cleaner must be an account member: office surfaces are gated on
# owner/admin role, and field surfaces scope by the active account.
case Accounts.get_user_role(owner_scope, cleaner.id, account.id) do
  nil -> {:ok, _} = Accounts.add_user_to_account(owner_scope, cleaner.id, account.id, :member)
  _role -> :ok
end

IO.puts("""

QA seed complete.

  Owner:   qa-owner@cleanercrm.test / #{qa_password}
  Cleaner: qa-cleaner@cleanercrm.test / #{qa_password}
  Account: #{account.name} (id: #{account.id})

  Log in at: http://127.0.0.1:4100/users/log-in
""")
