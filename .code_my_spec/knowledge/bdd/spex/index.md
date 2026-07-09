# BDD Spec Plan — Cleaner CRM

How BDD specs work in *this* project. The framework docs
(`philosophy.md`, `boundaries.md`, `writing_a_spex.md` in the harness
knowledge base) cover the generic rules; this file names the concrete
surfaces, fixtures, and anti-patterns for Cleaner CRM.

## Public surfaces a spec may drive

Specs act through LiveView routes (via `Phoenix.LiveViewTest`) and the
public controllers. Concretely:

**Office/admin side (owner persona):**
- `CleanerCrmWeb.ClientLive.*` — `/clients`, client + property + access management (story 832)
- `CleanerCrmWeb.ScheduleLive.Board` — `/schedule`, weekly dispatch board (833, 834, 846)
- `CleanerCrmWeb.QuoteLive.*` — `/quotes`, quote builder (835)
- `CleanerCrmWeb.InvoiceLive.*` — `/invoices` (836)
- `CleanerCrmWeb.ReminderLive` — reminder settings + delivery log (837)
- `CleanerCrmWeb.TimesheetLive` — time review + payroll export (838)
- `CleanerCrmWeb.QualityLive.*` — job review + scorecards (839)
- `CleanerCrmWeb.AuditLive` — audit trail (840)

**Cleaner field side (cleaner persona):**
- `CleanerCrmWeb.FieldLive.Today` — day view + change alerts (841, 843)
- `CleanerCrmWeb.FieldLive.Job` — checklist, photos, clock in/out, incident reports (842, 844, 845)

**Public (unauthenticated) surfaces:**
- `CleanerCrmWeb.PaymentController` — payment-link pages (836)
- `CleanerCrmWeb.ReminderController` — reminder confirm/reschedule links (837)
- Auth: `/users/register`, `/users/log-in` LiveViews (generated)

## Fixture inventory (`CleanerCrmSpex.Fixtures`)

- `user_fixture/1` — confirmed user (owner/office/cleaner depending on attrs)
- `unconfirmed_user_fixture/1` — pre-confirmation user for auth specs
- `user_scope_fixture/0,1` — scope wrapping a user, for seeding deeper state
- `valid_user_password/0`, `set_password/1` — password login in specs
- `account_fixture/2` — a company (tenant) owned by the given scope

Grow this list only when a spec's `given_` needs state whose creation
flow is covered by another spec. Every addition is a sanctioned bypass.

## Legal observable surfaces in `then_`

- LiveView render assertions: `assert render(view) =~ "Job scheduled"`
- LiveView navigation: `assert_patch/2`, `assert_redirect/2`
- Flash content via rendered layout
- Controller responses: `html_response(conn, 200)`, redirects on payment/reminder links
- Email delivery via `Swoosh.TestAssertions` (reminder + invitation emails)
- NOT legal: asserting on Repo rows, context return values, or PubSub
  messages via direct `assert_receive` on internals — observe what a
  user (or webhook peer) can observe.

## Project-specific anti-patterns

- Do not seed `CleanerCrm.Scheduling` jobs in `given_` by calling the
  context — the covered creation flow is the ScheduleLive board / plan
  form. If a spec needs "a scheduled job" as a precondition, either
  drive the UI in `given_` steps or add a sanctioned fixture here first.
- Do not flip `Notification` acknowledgment state directly — the whole
  point of story 843 is the acknowledgment round-trip through
  `FieldLive.Today`.
- Do not stub time by editing rows; recurrence/conflict scenarios pin
  wall-clock via plan dates chosen in the future.
- External HTTP (Stripe, Twilio, Resend, S3) is always cassette- or
  adapter-faked; a spec must never hit a live API.
