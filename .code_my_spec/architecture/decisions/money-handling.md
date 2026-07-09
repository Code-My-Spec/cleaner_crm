# Money Handling — integer cents, no money library

**Status:** Accepted

## Context

Quotes (835), invoices/payments (836), and pay/earnings (838, 844) all handle money. Research shows pay-transparency disputes are a core cleaner pain, so amounts must never drift from float arithmetic. The product is US-only, USD-only at MVP.

## Options Considered

- **Integer cents in Postgres** — exact, simple, matches Stripe's amount convention.
- **ex_money** — multi-currency correctness we don't need; adds a dependency and custom Ecto types.
- **Decimal columns** — exact but invites fractional-cent ambiguity in piece-rate math.

## Decision

Store all monetary amounts as integer cents (`:integer` columns, `_cents` suffix). Rate math (per-sqft, hourly proration) computes in `Decimal` and rounds half-up to cents at each persisted boundary. A small `CleanerCrm.Money` formatting helper renders `$X.XX`; Stripe amounts pass through unchanged.

## Consequences

- Multi-currency would require a migration to ex_money later; acceptable for a US-market MVP.
- Rounding policy (half-up at persistence boundaries) must be stated in Quoting and TimeTracking specs so earnings and invoice totals always reconcile.
