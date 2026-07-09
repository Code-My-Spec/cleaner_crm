# Recurrence Engine & Timezones — project-local recurrence with materialized jobs, tzdata

**Status:** Accepted

## Context

Story 833 is the product's differentiator: recurring plans with conflict detection across the entire series, not just the first visit (the named ZenMaid gap). Story 846 layers preferred-cleaner defaults onto generated visits. Cleaning cadences are simple (weekly/biweekly/every-4-weeks, fixed weekday/time), not arbitrary RFC 5545 RRULEs.

## Options Considered

- **Project-local recurrence module + materialized Job rows** — generate concrete jobs N weeks ahead (Oban cron); conflict detection becomes plain SQL over real rows.
- **RRULE library (e.g. `cocktail`)** — full RFC 5545 power we don't need; conflict detection against virtual occurrences is much harder than against rows.
- **Virtual occurrences computed on read** — no rows to detect conflicts against; breaks the core story.

## Decision

Write `CleanerCrm.Scheduling.Recurrence` as project-local code generating a 12-week rolling horizon of `Job` rows from each `RecurringPlan` (extended by a daily Oban job). `ConflictDetector` runs SQL overlap queries across the whole materialized series against jobs and availability blocks. Times are stored UTC; each Company has an IANA timezone (via `tzdata` + `DateTime.shift_zone/2`) used for materialization and display, keeping visits pinned to local wall-clock across DST.

## Consequences

- Adds `tzdata` dependency and a `timezone` field on Company.
- Plan edits must reconcile already-materialized future jobs (regenerate unstarted ones, flag manually-modified ones) — this logic lives in `Scheduling` and needs careful spec coverage.
- 12-week horizon bounds conflict detection; conflicts beyond the horizon surface as the horizon rolls forward.
