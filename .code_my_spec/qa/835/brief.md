# Qa Story Brief — 835: Build quotes with per-room, per-sqft, or hourly pricing

## Tool

web

## Auth

- Login URL: `http://127.0.0.1:4100/users/log-in`
- Password form fields: `input[name="user[email]"]`, `input[name="user[password]"]`
- Owner creds: `qa-owner@cleanercrm.test` / `qa password 1234`
- Log in as the owner (this story is `persona:owner`). Success redirects to `/`.

## Seeds

- `mix run priv/repo/qa_seeds.exs` (idempotent) — creates owner `qa-owner@cleanercrm.test`,
  cleaner `qa-cleaner@cleanercrm.test` (both password `qa password 1234`), and account
  "QA Sparkle Cleaning Co". No story-specific seeds needed — the rate card and quotes
  are created live during the session via `CleanerCrmWeb.QuoteLive.Builder` at
  `/quotes/new`.

## What To Test

Builder page (`/quotes/new`) has two forms: `[data-test='rate-card-form']` (persists
immediately on submit) and `[data-test='quote-form']` (in-memory until sent, phx-change
triggers `validate`). Model-specific inputs (`room-bedroom-count-input`,
`room-bathroom-count-input`, `square-feet-input`, `hours-input`) only carry their
`data-test` attribute while their model is selected — the underlying `<input>` stays
mounted but inert otherwise, so absence of the `data-test` attribute (not the element)
is the signal to check.

- **Criterion 7112 — per-room quote:** On `/quotes/new`, select pricing model "Per room",
  enter bedroom/bathroom counts. Expect `room-bedroom-count-input` and
  `room-bathroom-count-input` visible/tagged; `square-feet-input` and `hours-input`
  absent (no `data-test`).
- **Criterion 7114 — switching model clears inputs:** Starting from a per-room quote with
  values entered, switch pricing model to "Hourly". Expect the per-room inputs to lose
  their `data-test` tag (or read blank/hidden) and `[data-test='quote-total']` to reset to
  `$0.00` (not a stale per-room total).
- **Criterion 7116 — per-sqft total from rate card:** Submit `[data-test='rate-card-form']`
  with per-sqft rate = 10 cents ($0.10/sqft). Then on the quote form select "Per square
  foot" and enter 2000 sqft. Expect `[data-test='quote-total']` = `$200.00`.
- **Criterion 7119 — phone lead, no site visit:** With a bedroom rate of $50.00 and
  bathroom rate of $30.00 saved on the rate card, fill client name + phone (no address
  needed), pick "Per room", 3 bedrooms / 1 bathroom, click
  `[data-test='send-quote-button']`. Expect a patch to `/quotes/:id`, status badge
  `[data-test='quote-status']` = "Sent", total `$180.00` (3×$50 + 1×$30), and no
  "Schedule a site visit" text anywhere on the page.
- **Criterion 7120 — missing rate blocks finalize:** With no hourly rate configured (fresh
  rate card, or explicitly blank the hourly rate field), select "Hourly", enter 3 hours,
  click `[data-test='send-quote-button']`. Expect it does NOT navigate/patch away —
  `[data-test='missing-rate-warning']` appears, `[data-test='quote-total']` stays
  `$0.00`, and the hours value (3) is preserved in the input.
- **Criterion 7122 — sent quote frozen against rate changes:** Send a per-sqft quote at
  $0.10/sqft × 2000 sqft = `$200.00` (per 7116). Note the resulting `/quotes/:id` path.
  Go back to `/quotes/new`, raise the per-sqft rate to $0.20, save the rate card. Revisit
  the earlier sent quote's URL. Expect it still reads `$200.00`, not `$400.00`.
- Exploratory: try leaving pricing model unselected and submitting; try negative/zero
  room counts; check the `/quotes` index lists sent quotes with correct totals.

## Result Path

`.code_my_spec/qa/835/` (screenshots in `.code_my_spec/qa/835/screenshots/`); the
canonical result is the `submit_qa_result` DB attempt + linked issues, not a file here.

## Setup Notes

The rate card and quote-draft are both plain LiveView socket assigns until
`send_quote` is clicked — nothing is persisted to Postgres before that point, so there's
no need to reset any rate-card row between scenarios beyond re-submitting the
rate-card form with new values. Money is stored/rendered in cents via
`CleanerCrm.Money.format_cents/1`, formatted as `$X.XX`.
