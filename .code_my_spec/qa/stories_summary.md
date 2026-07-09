# Stories

## Story 832 — Manage clients and properties with access details

As a cleaning business owner, I want to manage clients and their properties — addresses, parking notes, entry method (key/lockbox/alarm codes), pets, and cleaning preferences — so that every job automatically carries authoritative entry and scope information and cleaners never get locked out or blindsided. (Research: key/entry management is a chronic owner burden; scattered access info is a top cleaner pain — docs/research/cleaner-pain-points.md §1.7, §2.2)

- Add a property under an existing client
- Reject a property with no client
- Save a property with a valid service address
- Reject a property with a blank address
- Job brief inherits property access details
- Updated code propagates to future jobs
- Entry code change is logged
- Deactivate a client with upcoming jobs
- Block hard delete of a client with upcoming jobs

## Story 833 — Schedule recurring cleaning plans with series-wide conflict detection

As a cleaning business owner, I want to create weekly/biweekly/monthly recurring cleaning plans that detect conflicts across the entire series (not just the first visit) and respect per-cleaner availability blocks, so that my calendar stays reliable without manually auditing future dates. (Research: ZenMaid detects conflicts only on first visit; owners want cleaner-unavailability blocking — pain-points §1.1, §4)

- Weekly plan generates the full series
- Conflict on a later occurrence is detected
- Clean series saves without warnings
- Assign a cleaner within their available hours
- Block assignment during a time-off block
- Block an overlapping double-booking
- Owner reviews conflicting dates before saving

## Story 834 — Dispatch from a single weekly schedule board

As a cleaning business owner, I want a single-screen weekly board showing every cleaner's schedule where I can assign/reassign jobs, so that I can dispatch and rebalance the week at a glance instead of clicking through tabs. (Research: MaidCentral users explicitly wish for "every employee's schedule for the entire week on a single screen" — pain-points §1.1, §4)

- See the whole week at a glance
- Reassign a job to another cleaner
- Block reassigning onto a conflicting slot
- Dispatch an unassigned job from the board
- Reassignment reaches the cleaner's schedule

## Story 835 — Build quotes with per-room, per-sqft, or hourly pricing

As a cleaning business owner, I want to build quotes using per-room, per-square-foot, or hourly pricing models with my own rate card, so that I can quote new work quickly and profitably without an in-person walkthrough for every lead. (Research: no pricing model is clean and underpricing is the #1 owner mistake — pain-points §1.4)

- Owner builds a per-room quote
- Switching pricing model clears the other model's inputs
- Per-square-foot total computes from the rate card
- Owner quotes a phone lead without visiting the property
- Missing rate on the chosen model blocks finalizing
- Rate-card change does not alter an already-sent quote

## Story 836 — Invoice completed jobs and collect payment

As a cleaning business owner, I want jobs to generate invoices on completion and collect payment via card-on-file or payment link, so that I get paid without chasing clients and disputes are backed by proof-of-work evidence. (Research: payment failures and chargebacks are acute owner pains — pain-points §1.8)

- Completing a job generates its invoice
- Auto-charge the card on file
- Client with no card on file pays via payment link
- Invoice shows the job's proof-of-work
- Card-on-file charge is declined
- Invoice marked paid on provider confirmation

## Story 837 — Send automated appointment reminders to clients

As a cleaning business owner, I want automated, reliably-delivered appointment reminders (email/SMS) with confirm/reschedule actions, so that cancellations and lockouts drop and my route density holds. (Research: fragile reminder delivery is an unresolved incumbent complaint; missed appointments are the top client grievance — pain-points §1.1, §1.6)

- Reminder fires at the configured lead time
- Client who prefers SMS gets a text reminder
- Reminder includes confirm and reschedule actions
- Client confirms the appointment
- Client requests a reschedule
- SMS reminder is undeliverable and falls back to email

## Story 838 — Track time and per-job pay in one system

As a cleaning business owner, I want cleaner clock-in/out and per-job pay (hourly or piece-rate) tracked in the same system as scheduling, with a payroll-ready export, so that I stop running a parallel time-tracking system and pay disputes disappear. (Research: owners maintain separate clock-in systems; no payroll integration is a named ZenMaid gap — pain-points §1.3, §4)

- Cleaner clocks in and out of an assigned job
- Cleaner tries to clock in on a job not assigned to them
- Hourly job pays rate times worked hours
- Per-job piece rate pays a fixed amount regardless of time
- Running pay-period total builds as jobs complete
- Owner exports a completed pay period to CSV
- Cleaner forgets to clock out
- Export blocked while an unresolved time entry remains

## Story 839 — Review photo proof and quality scorecards per job

As a cleaning business owner, I want completed jobs to show checklist completion, before/after photos, and a quality scorecard per cleaner over time, so that I can verify work I can't inspect in person, coach consistently, and defend against complaints and chargebacks. (Research: verification is standard in STR tools but absent in residential/janitorial — the #3 synthesis gap — pain-points §1.5, §5)

- Cleaner completes a job with a fully checked checklist
- Cleaner tries to complete with unchecked required tasks
- Before and after photos attached with timestamps
- Completed job gets a quality score
- Owner reviews a cleaner's scorecard over time
- Owner pulls up job proof to answer a chargeback
- Photo taken offline uploads when signal returns

## Story 840 — See an audit trail of schedule and record changes

As a cleaning business owner, I want an audit trail showing who changed what (jobs, assignments, client records, prices) and when, so that I can untangle scheduling mistakes and hold my office team accountable. (Research: direct MaidCentral user wish — "an audit trail feature to track who makes changes" — pain-points §4)

- Office staff reschedules a job and it is logged
- Price change records old and new value
- Nobody can alter or delete an audit entry
- Owner filters the trail to find who moved a job
- Automated recurring job generation is attributed to the system

## Story 841 — See today's jobs with everything needed to get in the door

As a cleaner, I want a mobile day view listing my jobs in order with address, parking, entry method, codes, pet notes, and client preferences on each job card, so that I never dig through group texts or get locked out. (Research: scattered access info causes lockouts; group chats bury critical details — pain-points §2.2, §2.5)

- Cleaner sees today's jobs in start-time order
- Another cleaner's jobs are not shown
- Access code appears on the day of the job
- Access code stays hidden before the job date
- Job card shows the full get-in-the-door brief
- Missing optional detail shows a clear placeholder
- Updated lockbox code propagates to future jobs
- Day off shows an empty-day state

## Story 842 — Work each job from a room-by-room checklist with photo proof

As a cleaner, I want each job to present a room-by-room checklist defining exactly what's in scope, with the ability to check off tasks and attach before/after photos, so that scope is never ambiguous and I'm protected from "missed spot" blame for tasks that weren't agreed to. (Research: scope ambiguity is the top cleaner frustration; photo checklists proven by STR tools — pain-points §2.1, §3.3)

- Checklist opens grouped by room
- Out-of-scope task is not on the checklist
- Checking tasks advances progress
- Before and after photos attach to a task
- Job completes when all required items are done
- Completion blocked with a required task unchecked
- Photo taken offline uploads when signal returns

## Story 843 — Get loud, acknowledged alerts when my schedule changes

As a cleaner, I want schedule changes (added/moved/cancelled jobs) pushed to me as notifications that I explicitly acknowledge — with the office seeing unacknowledged changes — so that mid-day changes actually reach me and same-day cleanings aren't silently missed. (Research: undelivered assignment changes are the most common cause of missed same-day cleanings — pain-points §2.4)

- Moved job notifies the cleaner
- Cancelled job notifies the cleaner
- Acknowledging clears the pending change
- Unacknowledged change keeps prompting
- Office sees who has not acknowledged
- Never-acknowledged same-day change escalates
- Push failure falls back to SMS

## Story 844 — Clock in/out per job and see my earnings build

As a cleaner, I want to clock in/out on each job (or see its piece-rate) and watch my per-job and pay-period earnings accumulate transparently, so that I trust I'm being paid for all my work including drive time policies I can see. (Research: pay opacity and unpaid drive time breed distrust; pay transparency is the stickiest cleaner feature — pain-points §2.3)

- Cleaner clocks in to their assigned job
- Cleaner cannot clock in to a job assigned to someone else
- Clocking in to a second job while already clocked in
- Clock out then clock in to the next job
- Hourly job earnings computed from clocked time
- Piece-rate job shows its fixed rate up front
- Running pay-period total grows as jobs complete
- Cleaner sees the drive-time policy with their earnings

## Story 845 — Report damage, missing items, or unsafe conditions from the job

As a cleaner, I want to file a timestamped photo report of damage, missing items, or unsafe conditions directly from the job screen, so that the office and client hear it from the record — not a text thread — and I'm protected from blame. (Research: damage/missing-item reporting is standard in STR tools and absent elsewhere; lone-worker safety is under-served — pain-points §2.7, §3.3)

- Cleaner files a damage report from the job screen
- Report carries the filing time and cleaner automatically
- Submitted report cannot be altered
- Damage report without a photo is blocked
- Unsafe-condition report can be filed without a photo
- Office is notified when a report is filed

## Story 846 — Keep the same cleaner on the same home

As a cleaning business owner, I want recurring plans to prefer the client's assigned cleaner and warn me when I assign someone else, so that clients get the consistency they pay for and retention stays high. (Research: same-cleaner-to-same-home matching is a distinct residential pain — pain-points §3.1)

- Owner sets a preferred cleaner on a recurring plan
- New recurring visit is pre-assigned to the preferred cleaner
- Owner is warned when reassigning away from the preferred cleaner
- Substitute for one visit leaves the plan's preferred cleaner intact
- No warning when the plan has no preferred cleaner