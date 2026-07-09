# Qa Story Brief

## Tool

web (all portal routes are LiveViews behind a magic-link session cookie set by `PortalController#access`, not a bearer token — must use the browser, never curl with a manually-built cookie).

## Auth

No password. A visit to `GET /portal/access/:token` sets `session["portal_client_id"]` and redirects to `/portal`. Two ready-made tokens (inserted directly against `portal_sessions` — see Seeds):

- Valid, 7-day: `qa850validtoken1234567890abcdefg` for client "QA Card Client 836"
- Expired (1 hour ago): `qa850expiredtoken1234567890abcd` for the same client

Plus a REAL magic-link harvested from the actual booking-confirmation flow (story 849): client "Happy Path Client", token `-vjXnP5Q-r8PeIsVkAnL7HvkYAK99dEcxGR9IW4AEvY` (visit `http://127.0.0.1:4100/portal/access/-vjXnP5Q-r8PeIsVkAnL7HvkYAK99dEcxGR9IW4AEvY`).

For the owner-side reassignment step, log in at `/users/log-in` with `qa-owner@cleanercrm.test` / `qa password 1234` (see plan.md).

## Seeds

Base seeds already applied. Story-specific data already in place (reused from earlier QA sessions rather than duplicated):

- Client "Happy Path Client" (`9dfe662c-a5e4-4dd6-a848-c7bbb81b6c21`) has one upcoming job on 2026-07-19 14:00, currently **unassigned** (`cleaner_id` null) — use this for the unassigned-placeholder check, then assign/reassign cleaners on it.
- Client "QA Card Client 836" (`5d125ff8-3500-4adc-a03b-a9a3e88e4e5d`) has a completed job (`e604cc04-c345-4638-9476-cfdbab3c33a6`) with checklist `773de3d5-200b-4dc3-b409-629bd609c741` (3 items, 2 before-photos + 1 after-photo across items) and an unpaid invoice `e991cf1d-623b-4a37-807d-a9ee7e690d09` — use this for checklist/photo history and invoice-match checks.
- Two cleaners to reassign between: id `3` "Alex Morgan QA1", id `4` "Alex Morgan QA2".
- Portal sessions inserted directly (see Auth) since there's no extra mix command available beyond `mix run priv/repo/qa_seeds.exs`; hashes computed with `openssl dgst -sha256` to match `PortalSession.hash_token/1`'s scheme exactly.

## What To Test

- **Valid magic link (7251):** visit the Happy Path Client's real portal link. Expect a redirect to `/portal` showing `[data-test='upcoming-visits']` and `[data-test='service-history']`, no password prompt anywhere.
- **Unassigned placeholder (7255):** on that same first portal view (before any reassignment), the 2026-07-19 visit card should show `[data-test='cleaner-not-assigned']` with text "Cleaner not yet assigned", and must NOT show `[data-test='assigned-cleaner-photo']`.
- **Expired/invalid link (7252):** visit `http://127.0.0.1:4100/portal/access/qa850expiredtoken1234567890abcd` — expect a 200 page (not the portal) with text matching /expired|invalid/i and an offer to "request a new/fresh link". Also try a token that was never inserted at all (e.g. `totally-bogus-token`) — expect the same denial, not a crash or information leak about which case it was.
- **Cleaner assigned shows name+photo (7253) and reassignment updates the view (7254):** log in as owner, go to `/schedule`, find the Happy Path Client's job card, use its inline `[data-test='job-<id>-cleaner-select']` (or equivalent assignment control) to assign cleaner id 3 (Alex Morgan QA1). Reload the client's `/portal` (same magic-link session) — the visit card should now show cleaner name "Alex Morgan QA1" and `[data-test='assigned-cleaner-photo']`, no more `cleaner-not-assigned`. Then reassign to cleaner id 4 (Alex Morgan QA2) on `/schedule` and reload `/portal` again — expect "Alex Morgan QA2" shown and "Alex Morgan QA1" no longer present on that visit card.
- **Completed visit shows checklist + before/after photos (7256):** open the valid QA Card Client 836 portal link, look at `[data-test='service-history'] [data-test='visit-e604cc04-c345-4638-9476-cfdbab3c33a6']` — expect checklist item task text visible, at least one `[data-test='before-photo']` and one `[data-test='after-photo']` image.
- **Portal proof-of-work matches invoice (7257):** log in as owner and view `/invoices/e991cf1d-623b-4a37-807d-a9ee7e690d09` — note the checklist item text and photo(s) shown (look for `[data-test='proof-of-work-photo']`). Compare against what the portal showed for the same job in the previous step — same task text, same before/after photo presence.
- Explore: try `/portal` directly with no session cookie (fresh/incognito-equivalent — clear cookies first) — expect a redirect/flash, not a crash, per `PortalAuth.on_mount/:require_client`. Try requesting another client's visit by guessing `/portal/visits/:job_id` with a job id that belongs to a different client while logged in as the first client's portal session — expect a 404/not-found rather than leaking the other client's visit (`Portal.get_visit!/2` is supposed to raise `Ecto.NoResultsError` for a mismatched client).
- Mobile spot-check: view `/portal` at 390x844 — check for the same header-overflow issue already filed against 848/849 (don't refile if reproduced) and confirm the portal's own content still renders usably.

## Result Path

Findings are filed via `create_issue` as discovered; final record is the `submit_qa_result` DB attempt (task id `6ba90b13-6ecf-4744-967a-3f7c4f5cfe21`). Screenshots: `.code_my_spec/qa/850/screenshots/`.
