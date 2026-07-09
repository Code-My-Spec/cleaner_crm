# Qa Story Brief

## Tool

web

## Auth

None required — `/book` is a public, unauthenticated route. No login needed.

## Seeds

Base seeds already applied: `mix run priv/repo/qa_seeds.exs` (owner qa-owner@cleanercrm.test / cleaner qa-cleaner@cleanercrm.test / account "QA Sparkle Cleaning Co", id `b4ecfdf7-95d9-4fc0-884a-353d9db1c473`).

`Booking.public_scope/0` resolves to the *most recently created* account (see moduledoc in `lib/cleaner_crm/booking.ex`). Only one account exists in this DB, so `/book` prices against QA Sparkle Cleaning Co's rate card.

There is no owner-facing UI yet for the `RateCard` used by `/book` (the existing `/quotes` surface is a different model — one-off custom quotes, `CleanerCrm.Quoting.Quote` — not the rate card). The rate card was configured directly via psql for this QA pass:

```
per_room_bedroom_rate_cents = 5000   ($50/bedroom)
per_room_bathroom_rate_cents = 3000  ($30/bathroom)
per_sqft_rate_cents = 20             ($0.20/sqft)
hourly_rate_cents = NULL             (unconfigured — used to test the "unsupported" criterion)
weekly_discount_percent = 15
biweekly_discount_percent = 10
monthly_discount_percent = 5
add_on_rates_cents = {"inside_fridge": 1500, "interior_windows": 2000}
```

Verify with: `psql -h localhost -d cleaner_crm_dev -c "select * from rate_cards;"`

## What To Test

- Navigate to `http://127.0.0.1:4100/book`. Confirm page renders styled (trust badges, form) with no contact fields visible yet, and no price shown before any input (AC: room-count pricing needs no contact info).
- Select pricing model "Per room", bedroom count 3, bathroom count 2. Expect live total `$210.00` ((3*50)+(2*30)=150+60=210) with no name/email/phone required to see it. (AC1: criterion 7215)
- Switch pricing model to "Per square foot", enter square feet 2000. Expect total `$400.00` (2000*0.20). (AC2: criterion 7216)
- Back on per-room, set bedroom count 2 / bathroom 0 → expect `$100.00`; change bedroom count to 3 → expect total updates live to `$150.00` with no page reload (check URL doesn't change, no full navigation). (AC3: criterion 7217)
- With bedroom 2 / bathroom 0 / frequency "One-time" → `$100.00`. Switch frequency to "Bi-weekly" → expect `$90.00` (10% off) and a discount note referencing "bi-weekly discount". (AC4: criterion 7218)
- With bedroom 2 / bathroom 0 (base `$100.00`), check "Inside fridge" and "Interior windows" add-ons → expect total `$135.00` (100+15+20). (AC5: criterion 7219)
- Select pricing model "Hourly" and enter an hours value → expect the `[data-test='unsupported-quote-message']` element with text containing "can't price this yet" and "request a custom quote" — NOT a `$0.00` total. (AC6: criterion 7220)
- With bedroom 2 / bathroom 2 rates (6000/3750 cents if re-seeded per spex, or use current rate card: pick any combo and note the exact total shown, e.g. $210.00 for bedroom 3/bathroom 2), fill the lead contact form (name/email/phone) and submit. Confirm it patches to `/book/accept/:token` and the SAME total is shown with no added fees. (AC7: criterion 7221)
- Explore: try 0/negative/blank bedroom counts, huge square footage, rapid input changes, and submitting the contact form with invalid email — note any crashes, wrong prices, or unhandled states.
- Mobile check: set viewport to 390x844 and screenshot `/book` to confirm it's usable at mobile width.
- Confirm static assets load (200) — no broken CSS/JS on `/book`.

## Result Path

Findings are filed via `create_issue` as discovered; final record is the `submit_qa_result` DB attempt (task id `28f51d76-22c3-4250-82e5-017e52352c3a`). Screenshots: `.code_my_spec/qa/848/screenshots/`.
