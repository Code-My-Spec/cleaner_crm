# Jobber — Research Report (Cleaning-Business Lens)

_Researched July 2026. Focused on residential/commercial cleaning and maid-service use cases._

## What Jobber Is

Jobber (getjobber.com) is a general-purpose field-service management (FSM) SaaS serving "home service" trades — landscaping, HVAC, plumbing, contracting, and cleaning. It bundles CRM, scheduling/dispatch, quoting, invoicing, payments, a client portal, a field mobile app, and a growing AI layer into one system. It is **horizontal**: cleaning is one of many industries it markets to, with a dedicated landing page ([getjobber.com/industries/residential-cleaning](https://getjobber.com/industries/residential-cleaning/)) but no cleaning-specific product architecture underneath.

---

## 1. Core Capabilities

Source: [getjobber.com/features](https://www.getjobber.com/features/), [residential-cleaning page](https://getjobber.com/industries/residential-cleaning/)

**Scheduling & Dispatch**
- Drag-and-drop calendar with color-coded, lane/column view (each cleaner or team is a column).
- "Find a Time" smart scheduling that suggests openings based on team availability and drive time.
- Route optimization, GPS tracking, and time tracking (jobs, breaks, drive time).
- Multiple team members can be assigned to a single job — supports two-person cleaning teams; both cleaners see the job in their app.

**Recurring Jobs**
- Set up a weekly/bi-weekly/monthly recurring clean once; Jobber auto-generates future visits, reminders, and invoices.
- Users can separate recurring vs. one-time vs. seasonal work via a tag system (but tags are applied manually per client).

**Client Management (CRM)**
- Client records store property details, entry codes, pet names, product preferences — visible to cleaners on mobile.
- Client Hub: a 24/7 self-serve portal where clients approve quotes, view appointments, track jobs, see service history, and pay invoices. Property managers value this for reducing calls.

**Quoting**
- Quote templates with optional/upsell line items, images, and reviews from past work.
- Advanced quote customization (visuals, upsells) gated to the Grow tier.

**Invoicing & Payments**
- Batch invoicing across multiple visits, clients, or services.
- Automated invoice follow-ups by email/text; card-on-file autopay for recurring clients (Jobber Payments).

**Mobile App (field workers)**
- Checklists, job details, internal notes, photos, files/media library, time tracking, @mention team chat.

**Client Hub / Portal** — see CRM above; a genuine strength and differentiator.

**Automations**
- Automated appointment reminders, "on-my-way" texts, review requests, invoice follow-ups, and email marketing campaigns (AI-assisted drafts).

**Reporting** — built-in reports exist but are widely described as shallow (see gaps).

**Integrations** — 100+ integrations; two-way QuickBooks Online sync, one-way Xero, Gusto payroll, plus a marketplace.

**AI features** (source: [getjobber.com/features/ai](https://www.getjobber.com/features/ai/), [Copilot launch PR](https://www.prnewswire.com/news-releases/jobber-launches-copilot-the-first-of-several-ai-powered-products-aimed-at-making-home-service-business-ownership-simpler-than-ever-before-302264047.html))
- **Jobber Copilot**: AI assistant for business-data analysis, marketing content (blog/social drafts), and coaching; uses your Jobber data. Free in beta.
- **AI Receptionist**: answers calls/texts 24/7, books jobs into the calendar, captures leads. Included on Plus; otherwise a paid add-on.
- Jobber AI Voice and AI Chat available across tiers.

---

## 2. Pricing (2025–2026)

Sources: [getjobber.com/pricing](https://www.getjobber.com/pricing/), [MyQuoteIQ breakdown](https://myquoteiq.com/jobber-pricing-breakdown-2026/), [Tekpon](https://tekpon.com/software/jobber/pricing/)

Pricing varies by commitment. Official page (annual-prepaid → monthly-no-commitment ranges):

| Plan | Annual (prepaid) | Monthly (no commitment) | Users included | Extra user |
|------|------|------|------|------|
| **Core** | $29/mo | $49/mo | 1 | $29/mo |
| **Connect** | $99/mo | $139/mo | 1 (up to 5) | $29/mo |
| **Grow** | $149/mo | $199/mo | 1 (up to 5) | $29/mo |
| **Plus** | $399/mo | $499/mo | 5 (up to 15) | $29/mo |

_Note: some resellers list slightly different team-plan bundles (e.g., Connect ~$119–169). Numbers above are from Jobber's own pricing page; treat exact figures as commitment-dependent._

**Price anchor:** entry ~**$39–49/mo** for a solo operator (Core); realistic small-team cost lands at **$119–199/mo** (Connect/Grow) once you add users and need online booking/automations.

**Feature gating (matters for cleaners):**
- Online booking, automated reminders, autopay, **checklists**, and QuickBooks sync require **Connect** (not on Core).
- Two-way SMS, job costing, automatic time tracking require **Grow**.
- Files/media library, team @mentions, Marketing Suite, AI Receptionist require **Plus**.

**Add-ons (on top):** Marketing Suite ~$79/mo, AI Receptionist ~$29–99/mo (source-dependent), Pipeline ~$49/mo, plus Reviews/Campaigns/Referrals add-ons cited by resellers.

---

## 3. What Cleaning Businesses Like

- **Recurring automation done right for the happy path**: "set up a bi-weekly clean once and Jobber handles every future booking, reminder, and invoice" ([HomeServiceSorted](https://homeservicesorted.com/cleaning/jobber-review/)).
- **Client Hub self-serve portal** — cuts inbound calls, praised by property managers.
- **Autopay + batch invoicing** — card-on-file recurring billing and one-click multi-visit invoices.
- **Client preference storage** — entry codes, pet names, product prefs surfaced to cleaners in the field.
- **Two-person team assignment** and predictable lane-view dispatch for weekly contracts.
- **Polished, mature platform** — strong reviews from companies running 10–300+ recurring clients with 1–15 cleaners.

---

## 4. Where Jobber Falls Short for Cleaners

All items below are sourced, not invented.

1. **Per-user pricing punishes growth.** The 1→2 user jump goes from ~$49 (Core) to ~$119 (Connect) — a "143% increase for one additional user," and "not obvious from the pricing page." Owners with ~10 cleaners call the per-user bill "absurd." Billing complaints were the #1 category across 127 analyzed negative reviews (32%). ([HomeServiceSorted](https://homeservicesorted.com/cleaning/jobber-review/), [JJ Andrade](https://jjandradellc.com/blog/2026-02-18-jobber-alternatives-cleaning-business/))

2. **No pay-per-clean / piece-rate payroll.** Cleaning companies that pay a % of job total or flat rate per clean must run a separate payroll workflow — no native calculator. Tips aren't natively tracked (workaround: custom invoice line item) and tips aren't linked to payroll; no trainer/trainee pay. ZenMaid ships this as core. ([Kore Komfort](https://korekomfortsolutions.com/jobber-for-cleaning-businesses/), [The Cleaning Software](https://thecleaningsoftware.com/compare/jobber/))

3. **No cleaning-grade QA/inspection.** Only generic job forms — no room-by-room quality ratings, area-specific issue flagging, or pass/fail inspection reports that commercial contracts require. ([Kore Komfort](https://korekomfortsolutions.com/jobber-for-cleaning-businesses/))

4. **Recurring management "feels like an afterthought."** Despite being the bread-and-butter of residential cleaning, deeper recurring workflows rely on manual work (e.g., tags typed per client), and specialized needs — room-by-room checklists, team rotation, client-specific access instructions — are workarounds, not native features. ([JJ Andrade](https://jjandradellc.com/blog/2026-02-18-jobber-alternatives-cleaning-business/))

5. **No supply/inventory tracking and no lone-worker safety.** No native way to track chemical/supply usage; no equivalent to a solo-cleaner SOS/safety alert. ([Kore Komfort](https://korekomfortsolutions.com/jobber-for-cleaning-businesses/))

**Also recurring in reviews:** email deliverability from generic `jobbermail.com` domains ("over 60% of estimates went unviewed"); declining support quality ("agents unable to answer basic questions," 30% of negative reviews); shallow reporting requiring manual exports; and field-app friction (extra screens/menu layers slow routine crew tasks). ([JJ Andrade](https://jjandradellc.com/blog/2026-02-18-jobber-alternatives-cleaning-business/), [HomeServiceSorted](https://homeservicesorted.com/cleaning/jobber-review/), [Buildbite](https://buildbite.com/insights/jobber-pricing-and-feature-review))

---

## 5. Positioning

Jobber is a **broad, horizontal FSM platform** — "the #1 field service management software" for home-service trades generally, not a cleaning-specific tool. Its cleaning landing page reframes generic features (scheduling, recurring visits, checklists, client hub) in cleaning language, but the underlying data model and workflows are trade-agnostic. This is exactly the seam cleaning-native competitors (ZenMaid, The Cleaning Software, etc.) attack: piece-rate pay, QA/inspection scoring, per-cleaner (not per-user) pricing, and cleaning-tuned recurring/rotation logic. Jobber's strengths — maturity, client hub, autopay, AI Copilot/Receptionist, broad integrations — are real; its weakness is that a maid service must bend a general tool to fit cleaning-specific operations.

---

### Source List
- https://www.getjobber.com/features/
- https://getjobber.com/industries/residential-cleaning/
- https://www.getjobber.com/pricing/
- https://www.getjobber.com/features/ai/
- https://www.getjobber.com/features/ai-receptionist/
- https://www.prnewswire.com/news-releases/jobber-launches-copilot-the-first-of-several-ai-powered-products-aimed-at-making-home-service-business-ownership-simpler-than-ever-before-302264047.html
- https://myquoteiq.com/jobber-pricing-breakdown-2026/
- https://tekpon.com/software/jobber/pricing/
- https://homeservicesorted.com/cleaning/jobber-review/
- https://jjandradellc.com/blog/2026-02-18-jobber-alternatives-cleaning-business/
- https://korekomfortsolutions.com/jobber-for-cleaning-businesses/
- https://thecleaningsoftware.com/compare/jobber/
- https://buildbite.com/insights/jobber-pricing-and-feature-review
