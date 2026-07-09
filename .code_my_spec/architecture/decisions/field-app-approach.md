# Cleaner Field Experience — mobile-responsive LiveView, SMS as the loud channel

**Status:** Accepted

## Context

Stories 841–845 are the cleaner's daily surface, used on phones, sometimes with poor connectivity. Research: cleaners are non-technical, onboarding budget is near zero (200–400% turnover in janitorial), and silent schedule changes are the top cause of missed cleanings. Incumbent gap: tech-only native apps with no office counterpart, or no cleaner app at all.

## Options Considered

- **Mobile-responsive LiveView (PWA-lite)** — one codebase, no app-store friction ("learnable in one shift", installable via home-screen), consistent with the stack.
- **Native app (Swift/Kotlin or React Native)** — better offline and push, but doubles the codebase and adds store review latency; kills MVP velocity.
- **LiveView Native** — promising but too immature to bet the core persona surface on.

## Decision

Build the cleaner surface as mobile-first responsive LiveView under `CleanerCrmWeb.FieldLive`, with large touch targets and minimal navigation. The "loud, acknowledged" alert channel (843) is SMS (already required for client reminders) deep-linking into the field app, where acknowledgment is recorded; unacknowledged alerts escalate to the office. Web Push can be added later without changing the model. Offline tolerance is scoped to photo-upload retry (LiveView external uploads with pending state), not full offline operation.

## Consequences

- No app-store presence at MVP; marketing implication accepted.
- True offline mode (viewing jobs with no signal) is deferred; job briefs render fast and cacheable, but live features need connectivity.
- SMS cost per alert is accepted as the price of reliability; per-message delivery status already tracked by the SMS ADR.
