# Cleaner CRM — Build Status

_Last updated: 2026-07-08 ~19:35 EDT by the autonomous build loop._

## CUSTOMER SIDE ADDED — all CodeMySpec requirements satisfied (again)

A second full pipeline pass added the customer-facing side (stories 848–853),
grounded in `docs/research/customer-side.md` and a third persona
(`cleaning-client`):

- **/book** — public instant-quote calculator (rooms/sqft/frequency/add-ons,
  priced from the owner's rate card, managed at **/quotes/rate-card**)
- **/book/accept/:token** — slot selection (future-only), cancellation-policy
  agreement (owner-configured at **/settings/booking**), Stripe card capture,
  lead → client+property+plan conversion, portal magic link issued
- **/portal** (magic-link sessions, no passwords) — upcoming visits with the
  named/photo cleaner, history with proof-of-work, reschedule/cancel within
  policy (fees shown before confirm), invoices with pay + digital tip (tips
  flow to cleaner earnings)
- **/reviews/:token** — post-visit review page (thank-you on completion +
  request ~24h later via Oban; low ratings route privately to the owner's
  **/reviews** inbox)

Verified: **143/143 BDD specs, 262/262 tests (incl. Wallaby journeys),
6/6 stories browser-QA PASSED** (with 9 real bugs found and fixed during QA,
incl. past-date booking/reschedule acceptance and two missing owner-settings
surfaces). New contexts: `Booking`, `Portal`, `Reviews`.

## Original build (stories 832–846)

`get_next_requirement` returns "All requirements satisfied. No actionable
requirements remain." The full pipeline ran end to end:

1. **Research** (Jobber, Housecall Pro, Maidily + cleaner pain points) → `docs/research/`
2. **Personas**: cleaning-business-owner (admin) + cleaner (user) → `.code_my_spec/personas/`
3. **15 user stories / 100 acceptance criteria** with Three Amigos rules & scenarios
4. **Architecture**: 8 domain contexts + surfaces, 8 project ADRs, cycle-free graph
5. **Implementation**: Clients, Scheduling (recurring plans, conflict detection,
   dispatch board), Quoting, Billing (Stripe), Notifications (reminders, SMS
   fallback, schedule-change alerts w/ escalation), TimeTracking (+ payroll CSV),
   Quality (checklists/photos/scorecards/templates/incidents), Audit, and the
   cleaner field app (`/field`)
6. **BDD**: 100/100 spex passing
7. **Unit/integration**: 170/170 tests passing (0 warnings, format clean)
8. **Per-story browser QA**: 15/15 stories PASS (real Vibium browser sessions;
   every criterion exercised live)
9. **End-to-end journeys**: 5/5 PASS (`.code_my_spec/qa/journey_result.md`)
10. **Wallaby regression tests**: `test/journeys/` — 5 features driving real
    headless Chrome against a real test endpoint (`PORT=4002 MIX_ENV=test mix test`)
11. **Issues**: every accepted app issue fixed and resolved (0 incoming, 0 accepted)

## Real bugs QA found and fixed (highlights)

- **Security (critical)**: office surfaces had no owner/admin role check — any
  cleaner could reschedule jobs, change prices, and export payroll. Fixed with
  `CleanerCrmWeb.RequireOfficeRole` (on_mount + plug) across the router.
- Board `phx-change` controls outside forms (silent no-ops in real browsers).
- Checklist template "Add Task" JS.dispatch never worked in real browsers —
  replaced with the native embeds_many checkbox pattern.
- Incident photo input outside its form — LiveView uploads never activated.
- Cancelled jobs vanished from the board, orphaning unacknowledged alerts and
  starving escalation.
- Edit Job dialog rescheduled silently (no cleaner notification).
- Nil-price jobs (all recurring-plan visits) crashed invoice generation — plans
  now carry a price; Billing degrades gracefully.
- Stripe/Twilio dev-mode crashes; Ecto 3.14 preload macro drift; duplicate
  webhook SIDs 500ing; export param crashes; job form not deriving client_id.

## Operational setup (current)

- **App**: OTP release at `/tmp/cleaner_crm_release` (embedded mode, immune to
  `_build` churn), serving http://127.0.0.1:4100.
  Restart: `lsof -ti :4100 | xargs kill -9; PHX_SERVER=true nohup /tmp/cleaner_crm_release/bin/cleaner_crm start > /tmp/cleaner_crm_release.log 2>&1 &`
  After code changes: `mix compile && mix release --overwrite && rm -rf /tmp/cleaner_crm_release && cp -R _build/dev/rel/cleaner_crm /tmp/cleaner_crm_release` then restart.
- **QA logins**: qa-owner@cleanercrm.test / qa-cleaner@cleanercrm.test
  (password "qa password 1234"); seeds: `mix run priv/repo/qa_seeds.exs`.
- **Test suite**: `PORT=4002 MIX_ENV=test mix test` (Wallaby needs the port free);
  BDD: `mix spex`.
- ONE browser driver at a time (Vibium is a shared instance).

## Remaining for John (not blockers)

- Integration credentials (`.code_my_spec/integrations/index.md`): Stripe test
  keys, Twilio, Resend, S3, CodeMySpec client creds — turns the `verify_*.sh`
  scripts green and enables live-mode adapters.
- Framework issues filed upstream: c8adf86e (FileSync deadlock), 5509cf00
  (subagent browser-tool registration), 8a98d152 (browser_screenshot doesn't
  persist files).
- Git: the repo has never been committed — everything is untracked. Consider an
  initial commit.
