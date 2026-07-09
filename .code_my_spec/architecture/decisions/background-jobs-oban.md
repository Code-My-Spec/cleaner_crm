# Background Jobs — Oban

**Status:** Accepted

## Context

Several stories need reliable scheduled/asynchronous work: reminder sends ahead of visits (837), recurring-plan job materialization (833), notification delivery with retries (843), invoice generation on completion (836), and payroll export generation (838). Losing a reminder or a materialization run damages exactly the trust this product sells.

## Options Considered

- **Oban** — Postgres-backed, persistent, unique jobs, cron plugin, the community standard.
- **Quantum** — cron scheduling only, no persistence or retries.
- **GenServer + Process.send_after** — no durability across restarts.

## Decision

Use Oban (standard OSS tier) with Postgres. Queues: `notifications`, `scheduling`, `billing`, `exports`. The cron plugin drives daily recurring-plan materialization and reminder scanning; unique-job constraints prevent duplicate reminders per (job, kind).

## Consequences

- Adds `oban` dependency and an Oban migration.
- Workers live inside their owning contexts (e.g. `CleanerCrm.Notifications.ReminderScheduler` schedules; a worker performs), keeping Boundary edges clean.
- Test env runs Oban in `:inline`/manual mode for deterministic specs.
