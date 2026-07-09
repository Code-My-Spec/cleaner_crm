# Payment Processing — Stripe via stripity_stripe

**Status:** Accepted

## Context

Story 836 requires invoicing completed jobs and collecting payment via card-on-file or payment link. Research shows payment friction (failed charges, chargebacks) is an acute owner pain; chargeback defense needs proof-of-work attached to invoices.

## Options Considered

- **Stripe (stripity_stripe)** — dominant API, SetupIntents for card-on-file, Payment Links, webhooks; well-maintained Elixir client.
- **Square** — popular with cleaning businesses (Maidily supports it) but weaker Elixir ecosystem.
- **Braintree/PayPal** — no compelling advantage; weaker Elixir support.

## Decision

Use Stripe through the `stripity_stripe` hex package. Card-on-file via Customer + SetupIntent + off-session PaymentIntents; payment links via Stripe Checkout Sessions; webhook endpoint (`CleanerCrmWeb`) confirms payment state transitions. All payment state changes recorded on `CleanerCrm.Billing.Payment` and driven by webhooks, never assumed from API call success.

## Consequences

- Requires Stripe API keys in runtime config (Dotenvy) and a webhook signing secret.
- Test strategy: ReqCassette/fixtures for API calls; webhook handling tested with signed test payloads.
- Square support (relevant to some cleaning businesses) deferred; gateway hidden behind `CleanerCrm.Billing.StripeGateway` so a second gateway can be added later.
