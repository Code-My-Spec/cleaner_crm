# Architecture Proposal

Component structure for Cleaner CRM — a cleaning-industry CRM with an owner/office admin side and a cleaner field side. Single-tenant company accounts, Phoenix 1.8 + LiveView, mobile-responsive web.

Authentication (`CleanerCrm.Users`), multi-tenant accounts (`CleanerCrm.Accounts` — the account is the cleaning company/tenant), and OAuth integrations (`CleanerCrm.Integrations`) already exist from the phx.gen.auth / cms_gen generators and are referenced as dependencies, not re-proposed here.

## Contexts

### CleanerCrm.Clients

- **Type:** context
- **Description:** Clients and their properties: addresses, parking notes, entry methods and codes, pets, and cleaning preferences — the authoritative access and scope record every job carries
- **Stories:** 832

#### Children

- CleanerCrm.Clients.Client (schema) [Stories: 832]: A paying customer with contact info and preferences
- CleanerCrm.Clients.Property (schema) [Stories: 832]: A serviced location with address, parking, pet, and preference notes
- CleanerCrm.Clients.AccessDetail (schema) [Stories: 832]: Entry method, lockbox/alarm codes, and emergency contact for a property, with day-of-job visibility rules

### CleanerCrm.Scheduling

- **Type:** context
- **Description:** Jobs, recurring plans, cleaner assignment, availability blocks, and series-wide conflict detection; the source of each cleaner's day view
- **Stories:** 833, 834, 841, 846

#### Children

- CleanerCrm.Scheduling.Job (schema) [Stories: 834, 841]: A scheduled visit to a property with assigned cleaners, time window, and status
- CleanerCrm.Scheduling.RecurringPlan (schema) [Stories: 833, 846]: A weekly/biweekly/monthly plan that generates jobs and records the client's preferred cleaner
- CleanerCrm.Scheduling.AvailabilityBlock (schema) [Stories: 833]: A period when a cleaner is unavailable for assignment
- CleanerCrm.Scheduling.Recurrence (module) [Stories: 833]: Generates job series from a plan's cadence
- CleanerCrm.Scheduling.ConflictDetector (module) [Stories: 833]: Detects conflicts across an entire series against jobs and availability blocks

### CleanerCrm.Quoting

- **Type:** context
- **Description:** Quotes built from the company's rate card using per-room, per-square-foot, or hourly pricing models
- **Stories:** 835

#### Children

- CleanerCrm.Quoting.Quote (schema) [Stories: 835]: A priced proposal for a client with status lifecycle
- CleanerCrm.Quoting.QuoteItem (schema) [Stories: 835]: A line item priced by room, area, or hours
- CleanerCrm.Quoting.RateCard (schema) [Stories: 835]: The company's configurable rates per pricing model
- CleanerCrm.Quoting.Pricing (module) [Stories: 835]: Computes quote totals from rate card and items

### CleanerCrm.Billing

- **Type:** context
- **Description:** Invoices generated on job completion and payment collection via card-on-file or payment link, with proof-of-work attached from Quality
- **Stories:** 836

#### Children

- CleanerCrm.Billing.Invoice (schema) [Stories: 836]: An invoice for a completed job with line items and status
- CleanerCrm.Billing.Payment (schema) [Stories: 836]: A payment attempt/result against an invoice
- CleanerCrm.Billing.StripeGateway (module) [Stories: 836]: Stripe integration for cards on file, payment links, and webhooks

### CleanerCrm.Notifications

- **Type:** context
- **Description:** Client appointment reminders with confirm/reschedule actions and cleaner schedule-change alerts requiring explicit acknowledgment, with office visibility into unacknowledged changes; email/SMS delivery abstraction
- **Stories:** 837, 843

#### Children

- CleanerCrm.Notifications.Notification (schema) [Stories: 837, 843]: An outbound message with delivery status and acknowledgment tracking
- CleanerCrm.Notifications.ReminderScheduler (module) [Stories: 837]: Schedules reminder sends ahead of upcoming jobs
- CleanerCrm.Notifications.Delivery (module) [Stories: 837, 843]: Provider abstraction for email and SMS delivery with retries

### CleanerCrm.TimeTracking

- **Type:** context
- **Description:** Clock-in/out per job, hourly and piece-rate pay, transparent per-job and pay-period earnings, and payroll-ready CSV export
- **Stories:** 838, 844

#### Children

- CleanerCrm.TimeTracking.TimeEntry (schema) [Stories: 838, 844]: A clock-in/out record tied to a job and cleaner
- CleanerCrm.TimeTracking.PayRate (schema) [Stories: 838]: A cleaner's pay basis — hourly rate or piece rate
- CleanerCrm.TimeTracking.Earnings (module) [Stories: 844]: Computes per-job and pay-period earnings for display
- CleanerCrm.TimeTracking.PayrollExport (module) [Stories: 838]: Generates payroll-ready CSV for a pay period

### CleanerCrm.Quality

- **Type:** context
- **Description:** Room-by-room checklists from per-property templates, before/after photo proof, incident reports (damage, missing items, unsafe conditions), and per-cleaner quality scorecards
- **Stories:** 839, 842, 845

#### Children

- CleanerCrm.Quality.ChecklistTemplate (schema) [Stories: 842]: Reusable room-by-room task template for a property or service type
- CleanerCrm.Quality.Checklist (schema) [Stories: 842]: The instantiated checklist for a job
- CleanerCrm.Quality.ChecklistItem (schema) [Stories: 842]: A single task with required flag, completion state, and photo attachments
- CleanerCrm.Quality.Photo (schema) [Stories: 842, 839]: A stored before/after or proof photo with offline-tolerant upload state
- CleanerCrm.Quality.IncidentReport (schema) [Stories: 845]: An immutable timestamped report of damage, missing items, or unsafe conditions
- CleanerCrm.Quality.Scorecard (module) [Stories: 839]: Aggregates checklist completion and outcomes into per-cleaner quality scores

### CleanerCrm.Audit

- **Type:** context
- **Description:** Append-only audit trail of who changed what and when across jobs, assignments, client records, and prices; system actions attributed to the system
- **Stories:** 840

#### Children

- CleanerCrm.Audit.AuditEntry (schema) [Stories: 840]: An immutable record of actor, action, subject, and old/new values
- CleanerCrm.Audit.Recorder (module) [Stories: 840]: API other contexts call to append entries

## Surface Components

### CleanerCrmWeb.ClientLive

- **Type:** live_context
- **Description:** Client and property management for the office: contact info, properties, access details, pets, and preferences
- **Stories:** 832

#### Children

- CleanerCrmWeb.ClientLive.Index (liveview) [Stories: 832]: List and search clients
- CleanerCrmWeb.ClientLive.Show (liveview) [Stories: 832]: Client detail with properties and access info
- CleanerCrmWeb.ClientLive.FormComponent (liveview_component) [Stories: 832]: Create/edit client
- CleanerCrmWeb.ClientLive.PropertyFormComponent (liveview_component) [Stories: 832]: Create/edit property with access details

### CleanerCrmWeb.ScheduleLive

- **Type:** live_context
- **Description:** Office scheduling: single-screen weekly dispatch board and recurring plan management with conflict warnings and preferred-cleaner enforcement
- **Stories:** 833, 834, 846

#### Children

- CleanerCrmWeb.ScheduleLive.Board (liveview) [Stories: 834, 846]: Weekly board of every cleaner's schedule with assign/reassign
- CleanerCrmWeb.ScheduleLive.PlanFormComponent (liveview_component) [Stories: 833, 846]: Create/edit recurring plans with series-wide conflict display
- CleanerCrmWeb.ScheduleLive.JobFormComponent (liveview_component) [Stories: 834]: Create/edit a single job

### CleanerCrmWeb.QuoteLive

- **Type:** live_context
- **Description:** Quote building with per-room, per-sqft, and hourly pricing off the company rate card
- **Stories:** 835

#### Children

- CleanerCrmWeb.QuoteLive.Index (liveview) [Stories: 835]: List quotes with status
- CleanerCrmWeb.QuoteLive.Builder (liveview) [Stories: 835]: Interactive quote builder with live totals

### CleanerCrmWeb.InvoiceLive

- **Type:** live_context
- **Description:** Office invoicing: invoice list and detail with payment status and proof-of-work
- **Stories:** 836

#### Children

- CleanerCrmWeb.InvoiceLive.Index (liveview) [Stories: 836]: List invoices with payment status
- CleanerCrmWeb.InvoiceLive.Show (liveview) [Stories: 836]: Invoice detail with proof-of-work and payment actions

### CleanerCrmWeb.PaymentController

- **Type:** controller
- **Description:** Public payment-link pages where clients without a card on file pay an invoice
- **Stories:** 836

### CleanerCrmWeb.ReminderLive

- **Type:** liveview
- **Description:** Office configuration of reminder timing/channels and a delivery log showing failed sends
- **Stories:** 837

### CleanerCrmWeb.ReminderController

- **Type:** controller
- **Description:** Public confirm/reschedule endpoints clients reach from reminder messages
- **Stories:** 837

### CleanerCrmWeb.TimesheetLive

- **Type:** liveview
- **Description:** Office review of time entries and pay, with payroll CSV export per pay period
- **Stories:** 838

### CleanerCrmWeb.QualityLive

- **Type:** live_context
- **Description:** Office review of completed jobs: checklist completion, before/after photos, incident reports, and per-cleaner scorecards
- **Stories:** 839

#### Children

- CleanerCrmWeb.QualityLive.Review (liveview) [Stories: 839]: Completed-job review with photos and checklist results
- CleanerCrmWeb.QualityLive.Scorecards (liveview) [Stories: 839]: Per-cleaner quality trends

### CleanerCrmWeb.AuditLive

- **Type:** liveview
- **Description:** Filterable audit trail view for the owner
- **Stories:** 840

### CleanerCrmWeb.FieldLive

- **Type:** live_context
- **Description:** The cleaner's mobile-responsive field app: today's jobs with access info, job checklists with photo proof, clock-in/out and earnings, incident reporting, and acknowledged schedule-change alerts
- **Stories:** 841, 842, 843, 844, 845

#### Children

- CleanerCrmWeb.FieldLive.Today (liveview) [Stories: 841, 843]: Day view of jobs in order with access info and change alerts requiring acknowledgment
- CleanerCrmWeb.FieldLive.Job (liveview) [Stories: 842, 844, 845]: Single job workspace: checklist, photos, clock-in/out, earnings, and report actions
- CleanerCrmWeb.FieldLive.ChecklistComponent (liveview_component) [Stories: 842]: Room-grouped checklist with photo attachment and offline-tolerant uploads
- CleanerCrmWeb.FieldLive.IncidentFormComponent (liveview_component) [Stories: 845]: File damage/missing-item/unsafe-condition reports with photos
- CleanerCrmWeb.FieldLive.EarningsComponent (liveview_component) [Stories: 844]: Per-job and pay-period earnings display

## Dependencies

- CleanerCrmWeb.ClientLive -> CleanerCrm.Clients
- CleanerCrmWeb.ScheduleLive -> CleanerCrm.Scheduling
- CleanerCrmWeb.ScheduleLive -> CleanerCrm.Clients
- CleanerCrmWeb.QuoteLive -> CleanerCrm.Quoting
- CleanerCrmWeb.QuoteLive -> CleanerCrm.Clients
- CleanerCrmWeb.InvoiceLive -> CleanerCrm.Billing
- CleanerCrmWeb.PaymentController -> CleanerCrm.Billing
- CleanerCrmWeb.ReminderLive -> CleanerCrm.Notifications
- CleanerCrmWeb.ReminderController -> CleanerCrm.Notifications
- CleanerCrmWeb.TimesheetLive -> CleanerCrm.TimeTracking
- CleanerCrmWeb.QualityLive -> CleanerCrm.Quality
- CleanerCrmWeb.AuditLive -> CleanerCrm.Audit
- CleanerCrmWeb.FieldLive -> CleanerCrm.Scheduling
- CleanerCrmWeb.FieldLive -> CleanerCrm.Quality
- CleanerCrmWeb.FieldLive -> CleanerCrm.TimeTracking
- CleanerCrmWeb.FieldLive -> CleanerCrm.Notifications
- CleanerCrm.Clients -> CleanerCrm.Accounts
- CleanerCrm.Clients -> CleanerCrm.Audit
- CleanerCrm.Scheduling -> CleanerCrm.Clients
- CleanerCrm.Scheduling -> CleanerCrm.Accounts
- CleanerCrm.Scheduling -> CleanerCrm.Users
- CleanerCrm.Scheduling -> CleanerCrm.Audit
- CleanerCrm.Quoting -> CleanerCrm.Clients
- CleanerCrm.Quoting -> CleanerCrm.Audit
- CleanerCrm.Billing -> CleanerCrm.Scheduling
- CleanerCrm.Billing -> CleanerCrm.Clients
- CleanerCrm.Billing -> CleanerCrm.Quality
- CleanerCrm.Billing -> CleanerCrm.Audit
- CleanerCrm.Notifications -> CleanerCrm.Scheduling
- CleanerCrm.Notifications -> CleanerCrm.Clients
- CleanerCrm.Notifications -> CleanerCrm.Accounts
- CleanerCrm.Notifications -> CleanerCrm.Users
- CleanerCrm.TimeTracking -> CleanerCrm.Scheduling
- CleanerCrm.TimeTracking -> CleanerCrm.Accounts
- CleanerCrm.TimeTracking -> CleanerCrm.Users
- CleanerCrm.Quality -> CleanerCrm.Scheduling
- CleanerCrm.Quality -> CleanerCrm.Clients
