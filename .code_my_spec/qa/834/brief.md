# Qa Story Brief

Story 834 — Dispatch from a single weekly schedule board.

## Tool

web

## Auth

Login page: `http://127.0.0.1:4100/users/log-in`

Password-form selectors (below the magic-link form, may need scroll):
`input[name="user[email]"]`, `input[name="user[password]"]`.

Credentials used this session:
- Owner: `qa-owner@cleanercrm.test` / `qa password 1234`
- Ben (cleaner, real login): `qa-ben-834@cleanercrm.test` / `qa password 1234`

## Seeds

1. `mix run priv/repo/qa_seeds.exs` (base owner/cleaner/account — idempotent)
2. `mix run priv/repo/qa_seeds_834.exs` (story-specific cleaners/jobs — idempotent)

The story seed creates 4 cleaners (Ana QA834, Ben, Chloe QA834, Dana QA834)
and 8 jobs for the current week (Monday `2026-07-06`), printed with ids on
each run. Board route: `/schedule` — always shows the week containing
today, no week-navigation control exists yet.

Key jobs (see script output for exact ids/uuids each run):
- Mon/Tue/Wed/Thu 9-11am: one job per cleaner (Ana/Ben/Chloe/Dana) — whole-week check.
- Wed 1-3pm: Ana's job to reassign to Ben (no conflict).
- Wed 10am-12pm: Ben's existing job (conflict anchor).
- Wed 11am-12pm: Ana's job — moving this to Ben must be BLOCKED (overlaps Ben's 10-12).
- Thu 2-4pm: unassigned job — dispatch target.

## What To Test

- **See the whole week at a glance**: log in as owner, visit `/schedule`.
  Assert `[data-test='weekly-board']` is present and contains
  `[data-test='cleaner-column-<id>']` for Ana, Ben, Chloe, Dana, each with
  their Mon/Tue/Wed/Thu job card visible on one screen (no per-cleaner tab
  switching).
- **Reassign a job to another cleaner**: on the board, find Ana's Wed
  1-3pm job card, use its `select[data-test='job-<id>-cleaner-select']`
  to choose Ben. Assert the job card now appears under Ben's column and
  no longer under Ana's (no conflict warning shown).
- **Block reassigning onto a conflicting slot**: find Ana's Wed
  11am-12pm job card, use its cleaner-select to choose Ben (who has a
  10am-12pm job that day). Assert the job stays under Ana's column, does
  NOT appear under Ben's, and `[data-test='schedule-conflict-warning']`
  is shown.
- **Dispatch an unassigned job from the board**: assert the Thu 2-4pm job
  appears under `[data-test='unassigned-jobs']`. Use its cleaner-select to
  assign it to Chloe (or Dana). Assert it disappears from the unassigned
  lane and appears under that cleaner's column.
- **Reassignment reaches the cleaner's schedule**: after reassigning
  Ana's Wed 1-3pm job to Ben above, log out, log back in as
  `qa-ben-834@cleanercrm.test`, visit `/schedule` again. Assert the job
  appears under Ben's column and not under Ana's — proving the
  reassignment is durable server-side state, not owner-local UI state.
- Explore freely afterward: try reassigning a job to "Unassigned" (blank
  option), try an edit/cancel/delete button on a job card, watch for any
  500s or broken states.

## Result Path

`.code_my_spec/qa/834/screenshots/` (evidence only — findings go through `create_issue`, not a result file)
