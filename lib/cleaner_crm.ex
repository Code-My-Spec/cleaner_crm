defmodule CleanerCrm do
  @moduledoc """
  CleanerCrm keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  # Fixture modules live in test/support and only compile in :test —
  # exporting them unconditionally warns in dev.
  @test_only_exports (if Mix.env() == :test do
                        [ClientsFixtures, SchedulingFixtures, UsersFixtures]
                      else
                        []
                      end)

  use Boundary,
    deps: [],
    # CleanerCrmWeb.Endpoint.url() is invoked to build absolute links for
    # outbound emails and OAuth redirect URIs (invitation emails, OAuth
    # provider config) — the standard phx.gen.auth-style exception.
    dirty_xrefs: [CleanerCrmWeb.Endpoint],
    exports:
      @test_only_exports ++
        [
          Accounts,
          Accounts.Account,
          Accounts.Invitation,
          Accounts.Member,
          Accounts.MembersRepository,
          Audit,
          Audit.AuditEntry,
          Authorization,
          Billing,
          Billing.Invoice,
          Billing.Payment,
          Booking,
          Booking.Lead,
          Clients,
          Clients.Client,
          Clients.Property,
          Codemyspec.Client,
          CodeMySpec.Widget,
          Users,
          Users.User,
          Users.Scope,
          Integrations,
          Integrations.OAuthStateStore,
          Mailer,
          Money,
          Notifications,
          Notifications.Notification,
          Notifications.ReminderSettings,
          Portal,
          Portal.CancellationPolicy,
          Portal.PortalSession,
          Portal.Tip,
          Quality,
          Quality.Checklist,
          Quality.ChecklistItem,
          Quality.ChecklistTemplate,
          Quality.IncidentReport,
          Quality.Photo,
          Quality.Scorecard,
          Quoting,
          Quoting.Pricing,
          Quoting.Quote,
          Quoting.QuoteItem,
          Quoting.RateCard,
          Repo,
          Reviews,
          Reviews.Review,
          Scheduling,
          Scheduling.AvailabilityBlock,
          Scheduling.Job,
          Scheduling.RecurringPlan,
          TimeTracking,
          TimeTracking.Earnings,
          TimeTracking.PayRate,
          TimeTracking.TimeEntry
        ]
end
