# QA Plan — Cleaner CRM

## App Overview

Cleaner CRM is a Phoenix 1.8 + LiveView 1.2 app backed by Postgres (Ecto), single OTP release with one endpoint. In dev it listens on **http://127.0.0.1:4100** (`PORT` defaults to 4100 in `config/runtime.exs`; port 4000 is occupied by another app on this machine). Authentication is session-based via phx.gen.auth with magic-link *and* password login at `/users/log-in` (POST `/users/log-in` sets the session cookie; protected routes 302-redirect to the login page when unauthenticated). One router (`CleanerCrmWeb.Router`) with a `:browser` pipeline (CSRF-protected, `fetch_current_scope_for_user`) and a currently-unused `:api` pipeline; authenticated LiveViews live under the `:require_authenticated_user` live_session (`/users/settings`, `/accounts*`, `/integrations`), and domain surfaces (clients, schedule, quotes, invoices, field app) will mount under the same session as they are built. Dev extras: `/dev/dashboard` (LiveDashboard) and `/dev/mailbox` (Swoosh local mailbox — where magic-link and invitation emails land).

## Tools Registry

### Vibium browser (LiveView pages)

Use for anything interactive: LiveView forms, navigation, acknowledgment flows, screenshots. Start with `browser_start`, then `browser_navigate` to `http://127.0.0.1:4100`. Probed login form selectors (REAL, from the rendered page): the login page renders two forms — magic-link first, then password. Password login fields: `input[name="user[email]"]`, `input[name="user[password]"]`, checkbox `input[name="user[remember_me]"]`; CSRF is a hidden `_csrf_token` input handled automatically by form submit. Log in by filling the password form and submitting; success redirects to `/`. Example: `browser_navigate {url: "http://127.0.0.1:4100/users/log-in"}` → `browser_fill {selector: "input[name=\"user[email]\"]", value: "qa-owner@cleanercrm.test"}` → fill password → `browser_click` the password form's submit button.

### curl (controllers, redirects, response codes)

Use for public pages, redirect assertions, and any future JSON/API pipeline. Unauthenticated probe results: `GET /` → 200, `GET /users/log-in` → 200, `GET /users/settings` → 302 (to log-in). Session-authenticated calls: use the wrapper `.code_my_spec/qa/scripts/authenticated_curl.sh` — it performs the CSRF + cookie login dance (verified working: login POST → 302, `/users/settings` with session → 200). Examples: `.code_my_spec/qa/scripts/authenticated_curl.sh /users/settings -i` (default owner creds) or `.code_my_spec/qa/scripts/authenticated_curl.sh qa-cleaner@cleanercrm.test "qa password 1234" /accounts -o /dev/null -w "%{http_code}"`. Set `BASE_URL` to override the default `http://127.0.0.1:4100`.

### mix run (seeds and one-off setup)

Use to (re)seed QA data: `mix run priv/repo/qa_seeds.exs` (idempotent). Run the server itself with `mix phx.server` (background); confirm it's up with `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:4100/` → 200. Reset the dev DB entirely with `mix ecto.reset` (drops, recreates, migrates, runs `priv/repo/seeds.exs`), then re-run the QA seeds. Integration credential checks live in `.code_my_spec/qa/scripts/verify_*.sh` (stripe, twilio, resend, object_storage, codemyspec) — each prints one-line JSON with `"status": "ok"|"error"`; they need env vars documented in `.code_my_spec/integrations/index.md`.

## Seed Strategy

Single Repo (`CleanerCrm.Repo`, Postgres, dev DB `cleaner_crm_dev`). One QA seed script:

- `priv/repo/qa_seeds.exs` — run with `mix run priv/repo/qa_seeds.exs`. Idempotent (checks by email / existing account before inserting). Creates through real context flows (register → magic-link confirm → set password): **owner** `qa-owner@cleanercrm.test` / `qa password 1234`, **cleaner** `qa-cleaner@cleanercrm.test` / `qa password 1234`, and one account **QA Sparkle Cleaning Co** owned by the owner (`Accounts.create_account/2`). Prints credentials and the login URL on completion. Run it after every `mix ecto.reset`, and before any browser session that needs a logged-in user. As domain contexts land (Clients, Scheduling, Quality, …), extend this script with clients/properties/plans rather than adding bash loops — one BEAM boot, all entities.
- `priv/repo/seeds.exs` — stock Phoenix seed file, currently empty; runs automatically during `mix ecto.setup`/`ecto.reset`.

## System Issues

### Port 4000 occupied by another dev app

Another BEAM app on this machine listens on 4000 (and answers `/.well-known/oauth-authorization-server` with a `dev.codemyspec.com` issuer — it is NOT this app). Cleaner CRM's dev default was moved to **4100** (`config/runtime.exs`, `PORT` env still wins). If a probe of 4000 returns 200s, you are talking to the wrong app. Status: resolved (default port changed).

### `mix test` is rerouted to `mix agent_test`, which skips `ecto.create`

The harness rewrites `mix test`; on a fresh checkout the test DB may not exist and every test fails with `invalid_catalog_name`. Fix: `MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate` once. Status: resolved on this machine, will recur on fresh clones.

## Notes

The `:api` pipeline exists but has no routes yet; when API/webhook endpoints land (Stripe webhooks, Twilio status callbacks, reminder confirm links), add curl rows with real headers here. Emails (magic link, invitations) are viewable at `http://127.0.0.1:4100/dev/mailbox` in dev — use it to extract tokens during browser QA. Integration verify scripts are `pending` until the engineer supplies credentials (see `.code_my_spec/integrations/index.md`).
