# Cleaning Business Owner (admin persona)

## Role
Owner-operator of a residential maid service or small commercial cleaning company, typically 2–15 cleaners. Wears every hat: sales/quoting, scheduling and dispatch, hiring/training, payroll, quality control, client communication, and collections. Often still cleans occasionally, and runs the business from a phone in the field and a laptop at night. This persona is the buyer AND the day-to-day admin of the CRM.

## Goals
- Fill and densify the schedule: recurring weekly/biweekly plans, minimal drive time between jobs, no idle crews.
- Win work at profitable prices: quote fast (per-room, per-sqft, or hourly) without an in-person walkthrough for every lead.
- Keep clients: consistent quality with the same cleaner on the same home, automated reminders, and easy rebooking.
- Keep cleaners: transparent pay, clear job briefs, and fair per-job vs hourly accounting (onboarding a cleaner costs $870–$2,050; churn ripples to $37k–60k).
- Get paid without friction: invoicing, card-on-file, and defense against chargebacks/disputes with proof-of-work.
- See the whole week at a glance and know who changed what (single weekly schedule view; audit trail).

## Pain Points
- Last-minute cancellations/reschedules blow holes in route density; recurring-series conflicts are detected only on the first visit in incumbent tools.
- Runs parallel systems: separate clock-in/out, spreadsheets for payroll, group texts for dispatch — nothing flows into payroll (no Gusto-style integration in ZenMaid et al.).
- Quality control at distance: "missed spots" complaints, no photo proof or checklist enforcement outside STR-specific tools.
- Key/lockbox/alarm-code management across a rotating crew; lockouts cost route time.
- Software pricing resentment: per-seat pricing means ~$10k/yr at 10 users on Jobber "for essentially a scheduling app"; MaidCentral depth costs $450+/mo.
- No office/admin mobile app in tools like MaidCentral (tech-only apps); wants push alerts for tickets/changes.

## Context
- Interrupt-driven day; admin work happens in stolen moments. Mobile-first for triage, desktop for planning.
- Price-sensitive but pays for outcomes; already pays for 2–4 point tools (scheduling, payments, review requests, payroll).
- Segments vary: residential (recurring plans, keys, same-cleaner preference), commercial/janitorial (bids, night crews, 200–400% turnover, geofenced time), STR turnover (booking-calendar-driven, same-day windows, photo proof).

## Decision Drivers
- Unlimited or cheap seats (Maidily's unlimited-user pricing is a proven wedge vs per-seat Jobber/ZenMaid).
- Cleaning-native depth without MaidCentral's price/learning curve: checklists, photo proof, quality scorecards, recurring-revenue analytics.
- One system replacing three: scheduling + time tracking + payroll flow + payments.
- Reliability of the basics: reminders that deliver, payments that process (top ZenMaid complaints).

## Evidence
Proto-persona from desk research; see sources.md. Primary corpus: docs/research/cleaner-pain-points.md, docs/research/jobber.md, docs/research/housecall-pro.md, docs/research/maidily-and-cleaning-specific.md (all in this repo, compiled 2026-07-07). Key quantitative anchors: cleaner onboarding cost $870–$2,050 (ZenMaid); janitorial turnover 200–400% (Janitek); Jobber ~$10k/yr at 10 seats (MyQuoteIQ review); MaidCentral $450+/mo (Capterra). Validate with real owner interviews before load-bearing product bets.
