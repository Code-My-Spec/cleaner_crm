# Cleaning Client (customer persona)

## Role
The person who hires and pays a residential cleaning company — a busy homeowner or renter (often dual-income household, young kids, or a move-out deadline), occasionally a small landlord or Airbnb host. Interacts with the business almost entirely through its public web surfaces and messages: finds the company online, wants a price without a phone call, books, pays, and (if happy) comes back monthly or biweekly. This persona is the BUYER side of the CRM — no login exists for them today.

## Goals
- Get a real price in seconds, not a "we'll call you back": bedrooms/bathrooms/sqft/frequency/add-ons in, dollar amount out, before giving up contact details.
- Know who is coming and that it's safe: bonded/insured, background-checked, a named cleaner with a face — trust is the gate, not cleaning quality.
- Book, reschedule, or cancel online within a clear policy — without phone tag.
- One authoritative place to see upcoming visits, what was agreed (scope), what was done (proof-of-work photos), and what it cost.
- Pay without friction: card on file for recurring visits, a link for one-offs, and an easy way to tip digitally.
- Have complaints heard once and fixed — a re-clean guarantee beats arguing.

## Pain Points
- "Request a quote" friction: forms that promise a callback lose time-pressured jobs (move-outs) to whoever answers first.
- Bait-and-switch pricing: the quoted rate shifting after the visit is a top category complaint; price agreed up front should be the price charged.
- Trust vacuum: 73% of bad cleaning experiences trace to trust issues, not the cleaning — strangers with house keys, no idea who's coming or whether they're vetted.
- Missed appointments and silence: no confirmation, no on-my-way, no reliable reminder — the #1 client grievance in the owner-side research, seen from the other side.
- Opaque scope: "deep clean" means different things; disputes come from mismatched expectations, not bad work.
- Cash-only or awkward payment; no easy tipping path (over half of tips are digital now); no record of what was paid for what.
- Reviews only get asked for when something went wrong; happy customers are never prompted at the right moment.

## Context
- Mobile-first browsing, often evenings; will not create an account just to get a price — the quote calculator must be public, with the portal invite arriving after booking.
- Compares 2–3 providers in one sitting; instant-quote booking-first tools (BookingKoala, Launch27, ZenMaid forms) set the UX bar; Jobber's Client Hub and Housecall Pro's booking/review flows set the incumbent bar.
- Recurring clients expect the same cleaner every visit and a holiday-bonus tipping norm rather than per-visit tips.

## Decision Drivers
- Instant, transparent, guaranteed price (with frequency discount visible) over the lowest price.
- Visible trust signals at the point of decision: insurance/bonding, background checks, named-and-photographed cleaner, specific reviews, satisfaction guarantee.
- Self-service control: reschedule/cancel within a stated policy (24–48h notice norm), payment methods they manage themselves.
- Proof and accountability after the visit: photo evidence, itemized invoice, a place to flag issues that actually responds.

## Evidence
- docs/research/customer-side.md §1 (trust as #1 gate — 73% stat; upfront-pricing demand; self-service reschedule norms; digital tipping trends), §2 (Jobber Client Hub, Housecall Pro booking + review automation), §3 (instant-quote calculator anatomy), §4 (review-request mechanics: auto thank-you + ~24h delayed ask).
- docs/research/jobber.md (Client Hub: quote approval, appointments, history, payment; assigned-cleaner photos).
- docs/research/housecall-pro.md (online booking from Google; review automation as the single most-praised cleaner feature; card-on-file/Instapay).
- docs/research/cleaner-pain-points.md §1.1, §1.4, §1.6, §1.8 (owner-side mirrors: cancellations, underpricing, missed-appointment grievances, payment failures).
