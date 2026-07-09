defmodule CleanerCrmWeb.Router do
  use CleanerCrmWeb, :router

  import CleanerCrmWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CleanerCrmWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # No `:protect_from_forgery` — unlike the GET-only public routes below
  # (which can just use `:browser`), `/pay/:token` accepts a POST from a
  # client with no session and no CSRF token (a mailed or shared link).
  # `:fetch_current_scope_for_user` still runs — the root layout reads
  # `@current_scope` unconditionally, and this plug assigns `nil` when
  # no one's logged in rather than requiring an authenticated visitor.
  pipeline :public do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, html: {CleanerCrmWeb.Layouts, :root}
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :webhook do
    plug :accepts, ["json"]
  end

  # Office-only controller routes (e.g. the payroll CSV export) layer
  # this on top of `:require_authenticated_user`; office-only
  # LiveViews use the equivalent `CleanerCrmWeb.RequireOfficeRole`
  # on_mount hook instead, since a plug can't gate a live_session.
  pipeline :require_office_role do
    plug CleanerCrmWeb.RequireOfficeRole
  end

  scope "/", CleanerCrmWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", CleanerCrmWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:cleaner_crm, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CleanerCrmWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", CleanerCrmWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CleanerCrmWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/accounts", AccountLive.Index, :index
      live "/accounts/new", AccountLive.Form, :new
      live "/accounts/:id/edit", AccountLive.Form, :edit
      live "/accounts/picker", AccountLive.Picker, :index
      live "/accounts/:id", AccountLive.Manage, :show
      live "/accounts/:id/manage", AccountLive.Manage, :show
      live "/accounts/:id/members", AccountLive.Members, :show
      live "/accounts/:id/invitations", AccountLive.Invitations, :show

      live "/integrations", IntegrationLive.Index, :index

      live "/field", FieldLive.Today, :index
      live "/field/jobs/:id", FieldLive.Job, :show
    end

    # Office-only surfaces: dispatch, payroll, quality, invoicing,
    # clients, quotes, reminders, and the audit trail. Gated to
    # owners/admins by `CleanerCrmWeb.RequireOfficeRole` — a cleaner
    # is redirected to `/field` instead. See that module for why it's
    # a separate `live_session` from the one above.
    live_session :require_office_role,
      on_mount: [
        {CleanerCrmWeb.UserAuth, :require_authenticated},
        {CleanerCrmWeb.RequireOfficeRole, :default}
      ] do
      live "/clients", ClientLive.Index, :index
      live "/clients/new", ClientLive.Index, :new
      live "/clients/:id/edit", ClientLive.Show, :edit
      live "/clients/:id/properties/new", ClientLive.Show, :new_client_property
      live "/clients/:id", ClientLive.Show, :show
      live "/properties/new", ClientLive.Show, :new_property
      live "/properties/:id/edit", ClientLive.Show, :edit_property
      live "/properties/:id", ClientLive.Show, :show_property

      live "/schedule", ScheduleLive.Index, :index
      live "/schedule/plans/new", ScheduleLive.PlanLive, :new
      live "/schedule/plans/:id/edit", ScheduleLive.PlanLive, :edit
      live "/schedule/jobs/new", ScheduleLive.JobLive, :new
      live "/schedule/jobs/:id/assign", ScheduleLive.JobLive, :assign
      live "/schedule/jobs/:id", ScheduleLive.JobLive, :show
      live "/schedule/cleaners/new", ScheduleLive.CleanerLive, :new
      live "/schedule/cleaners/:id", ScheduleLive.CleanerLive, :show
      live "/schedule/cleaners/:cleaner_id/time-off/new", ScheduleLive.AvailabilityLive, :new

      live "/audit", AuditLive, :index

      live "/quotes", QuoteLive.Index, :index
      live "/quotes/rate-card", QuoteLive.RateCard, :edit
      live "/quotes/new", QuoteLive.Builder, :new
      live "/quotes/:id", QuoteLive.Builder, :show

      live "/quality", QualityLive.Review, :index
      live "/quality/scorecards", QualityLive.Scorecards, :index
      live "/quality/templates", QualityLive.Templates, :index
      live "/quality/templates/new", QualityLive.Templates, :new
      live "/quality/templates/:id/edit", QualityLive.Templates, :edit
      live "/quality/:job_id", QualityLive.Review, :show

      live "/timesheets", TimesheetLive, :index

      live "/invoices", InvoiceLive.Index, :index
      live "/invoices/:id", InvoiceLive.Show, :show

      live "/reminders", ReminderLive, :index

      live "/settings/booking", SettingsLive.BookingPolicy, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", CleanerCrmWeb do
    pipe_through [:browser, :require_authenticated_user, :require_office_role]

    get "/timesheets/export", TimesheetExportController, :show
  end

  scope "/integrations/oauth", CleanerCrmWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/:provider", IntegrationsController, :request
    get "/callback/:provider", IntegrationsController, :callback
  end

  scope "/", CleanerCrmWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{CleanerCrmWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/invitations/accept/:token", InvitationsLive.Accept, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete

    # Public confirm/reschedule links a client reaches from their
    # reminder — no login, so `:browser` (not `:require_authenticated_user`)
    # like the routes above. Plain `:browser`, not `:public`, so
    # `fetch_current_scope_for_user` still assigns `current_scope` for
    # the root layout.
    get "/reminders/confirm/:token", ReminderController, :confirm
    get "/reminders/reschedule/:token", ReminderController, :reschedule
  end

  scope "/", CleanerCrmWeb do
    pipe_through :public

    get "/pay/:token", PaymentController, :show
    post "/pay/:token", PaymentController, :create
  end

  scope "/webhooks", CleanerCrmWeb do
    pipe_through :webhook

    post "/stripe", StripeWebhookController, :create
    post "/twilio", TwilioWebhookController, :status
  end

  # Reviews (story 853): the public token-link review page needs no
  # login — mirrors `/invitations/accept/:token`'s `:current_user`
  # live_session so `current_scope` still mounts for the root layout —
  # while the owner's review inbox is office-only, gated the same way
  # as the other office surfaces above.
  scope "/", CleanerCrmWeb do
    pipe_through [:browser]

    live_session :reviews_public,
      on_mount: [{CleanerCrmWeb.UserAuth, :mount_current_scope}] do
      live "/reviews/:token", ReviewLive.Public, :show
    end
  end

  scope "/", CleanerCrmWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :reviews_office,
      on_mount: [
        {CleanerCrmWeb.UserAuth, :require_authenticated},
        {CleanerCrmWeb.RequireOfficeRole, :default}
      ] do
      live "/reviews", ReviewLive.Index, :index
    end
  end

  # Portal (client magic-link) — no user auth. `/portal/access/:token`
  # exchanges a mailed/booking-issued token for a portal session
  # (plain `:browser`, like the reminder confirm/reschedule links
  # above, so `fetch_session`/`fetch_current_scope_for_user` still
  # run); every other portal route sits behind
  # `CleanerCrmWeb.PortalAuth`'s own session check instead.
  scope "/", CleanerCrmWeb do
    pipe_through [:browser]

    get "/portal/access/:token", PortalController, :access

    live_session :portal,
      on_mount: [{CleanerCrmWeb.PortalAuth, :require_client}] do
      live "/portal", PortalLive.Home, :index
      live "/portal/visits/:id", PortalLive.Visit, :show
      live "/portal/invoices", PortalLive.Invoices, :index
    end
  end

  # Public booking funnel (stories 848/849) — no user auth, plain
  # `:browser` (like the reminder/reviews/portal public routes above)
  # so `current_scope` still mounts for the root layout. Both routes
  # share one view module, `BookingLive.Quote` — see its moduledoc for
  # why `BookingLive.Accept` isn't routed on its own.
  scope "/", CleanerCrmWeb do
    pipe_through [:browser]

    live_session :public_booking,
      on_mount: [{CleanerCrmWeb.UserAuth, :mount_current_scope}] do
      live "/book", BookingLive.Quote, :new
      live "/book/accept/:token", BookingLive.Quote, :accept
    end
  end
end
