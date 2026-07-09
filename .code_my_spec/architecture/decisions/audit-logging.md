# Audit Trail — project-local append-only audit table

**Status:** Accepted

## Context

Story 840: owners want to see who changed what and when (a direct MaidCentral user wish), including attributing automated recurring-job generation to the system. Entries must be immutable (criterion 7198) and filterable.

## Options Considered

- **Project-local `audit_entries` table + `Audit.Recorder`** — explicit, scoped to the events that matter, easy to attribute system actors.
- **paper_trail / ex_audit** — generic row-versioning; captures noise, awkward system-actor attribution, and both are lightly maintained.
- **Postgres triggers** — invisible to application code and hard to attribute to the acting user.

## Decision

Write a project-local `CleanerCrm.Audit` context: an append-only `audit_entries` table (actor_id nullable + `system` flag, action, subject type/id, old/new value maps as JSONB, company-scoped) with a `Recorder` API called explicitly from mutating context functions. No update/delete functions are exposed; a DB rule/constraint blocks UPDATE/DELETE as defense in depth.

## Consequences

- Explicit call sites mean a mutation can forget to record; Credo local check or code review must watch for this in mutating context functions.
- JSONB old/new maps keep the schema stable as audited entities evolve.
- Retention/archival policy deferred until data volume warrants it.
