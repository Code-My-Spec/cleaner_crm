# Mix.Tasks.CmsGen.Accounts

Generates the accounts context with Account, Member, and Invitation schemas,
repositories, authorization, email notifications, and LiveView pages.

    $ mix cms_gen.accounts

This generator requires `phx.gen.auth` to have been run first.

## Generated files

### Accounts & Members
  * `lib/app/accounts/account.ex` — Account schema (UUID pk, name, slug, type)
  * `lib/app/accounts/member.ex` — Member schema (role-based, user+account FKs)
  * `lib/app/accounts/accounts_repository.ex` — Account CRUD operations
  * `lib/app/accounts/members_repository.ex` — Member management
  * `lib/app/accounts.ex` — Accounts context with PubSub
  * `lib/app/authorization.ex` — Role-based authorization

### Invitations
  * `lib/app/accounts/invitation.ex` — Invitation schema with SHA256 token hashing
  * `lib/app/accounts/invitation_repository.ex` — Invitation data access
  * `lib/app/accounts/invitation_notifier.ex` — Swoosh email templates

### LiveViews
  * `lib/app_web/live/account_live/index.ex` — Account listing
  * `lib/app_web/live/account_live/manage.ex` — Account editing
  * `lib/app_web/live/account_live/members.ex` — Member management
  * `lib/app_web/live/account_live/picker.ex` — Account selection
  * `lib/app_web/live/account_live/form.ex` — Account form
  * `lib/app_web/live/account_live/invitations.ex` — Invitations tab
  * `lib/app_web/live/account_live/components/navigation.ex` — Tab navigation
  * `lib/app_web/live/account_live/components/members_list.ex` — Member table
  * `lib/app_web/live/account_live/components/accounts_breadcrumb.ex` — Breadcrumb
  * `lib/app_web/live/invitations_live/accept.ex` — Public acceptance page
  * `lib/app_web/live/invitations_live/form.ex` — Invite form component
  * `lib/app_web/live/invitations_live/components/pending_invitations.ex` — Pending list

### Migrations
  * `priv/repo/migrations/*_create_accounts_tables.exs` — Accounts + members + invitations