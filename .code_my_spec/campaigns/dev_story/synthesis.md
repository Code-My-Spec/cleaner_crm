# Cleaner CRM: Development Story Synthesis

Cleaner CRM is a CRM for residential cleaning businesses: clients and properties, recurring schedules with conflict detection, a dispatch board, quoting, Stripe invoicing, SMS and email reminders, timesheets and payroll export, quality checklists with photo proof, an audit trail, a mobile field app for cleaners, and a public customer side (instant quotes, online booking with card capture, a magic-link portal, review collection).

It was built through the CodeMySpec harness from a single prompt. John typed roughly 110 words on July 7, 2026 at 16:44 UTC. About 2.5 days of wall clock later the app was deployed to UAT with live Stripe, a real email provider, and an external tester's feedback batch already fixed. The initial commit on July 9 contained 1,404 files and 103,875 insertions: 21 stories across 3 personas, 143 BDD criteria (105 happy path, 38 failure path) backed by 115 BDD rules, and 262 tests including 5 Wallaby browser journeys. By the end of July 9 the suite stood at 331 tests. Along the way the harness spawned 172 subagents, ran 36 QA attempts across the 21 stories (all eventually passing), and filed 35 issues: 6 critical, 15 high, 9 medium, 5 low.

This document is the raw narrative, including the parts that went wrong. All times are UTC.

## Phase 1: One prompt to an architecture (July 7, 16:44 to 17:40)

The entire product brief:

> "Okay, you're inside CodeMySpec. It's a Complex development harness. Basically, I want you to use it to autonomously build me a cleaning CRM. I want you to research the incumbents, Jobber, Matally, and Housecall Pro. I want you to build a cleaner-specific CRM. I want you to do whatever research that you need about those other products, their capabilities, the pain points among cleaners. I want you to build the personas. There needs to be a cleaning business owner persona and a cleaner persona as the admin and user sides. I just want you to go through and autonomously build this whole thing for me on a loop."

Note the two personas John specified. That sentence comes back to bite him in Phase 5.

Four parallel research agents produced incumbent and pain-point reports in about five minutes, and caught an error in the prompt itself: "Matally" does not exist. The research agent resolved it to Maidily. Fifteen user stories followed in about a minute, each citing specific research findings. Five parallel Three Amigos agents worked example mapping across the stories: rules, scenarios, personas linked, zero open questions parked. One agent captured unprompted domain nuance: "photo required only for damage/missing-item, NOT for unsafe-condition (safety exemption)."

By 17:30 the agent had executed an architecture proposal: 8 contexts, roughly 40 components, dependency graph validated with no cycles, 8 architecture decision records. Project setup ran alongside, ending at 111 passing tests.

## Phase 2: The spec wave, and green in four hours (17:40 to 20:56)

Three waves of five parallel spec-writer agents produced 67 spec files across the first 10 stories, then the rest, all deliberately red first. One spec agent described its files as "genuinely red": every scenario drove a LiveView that did not exist yet.

The specs themselves had bugs, six distinct classes of them. Two stories specced opposite behavior for the same situation; a spec agent refused to paper over it: "worth a decision on which behavior is authoritative before implementation." Five files had wrong dollar math versus their own gherkin. A shared regex assumed integer job IDs while jobs use UUIDs, so story 846 read 0/5 against a fully correct implementation until the orchestrator fixed the test helper.

Parallelism produced collisions. A concurrent agent deleted shared_givens.ex while another story's specs depended on it. Multiple agents generated migrations at identical timestamps, blocking all migrations. A shared fixture bug touched roughly 28 call sites before one agent caught it and the orchestrator broadcast the fix to the fleet. The harness's Credo config had `enabled: []`, silently suppressing every check; the review gate was passing because it was not running. Self-caught, fixed.

At 19:41 John asked: "How's it going? got anything you can run in parallel with impl-schedulelive?" That one message triggered a six-agent implementation fan-out. Implementers respected file ownership ("FieldLive is off-limits for me", one reported, flagging the gap for its owner) and by 20:56, about 4 hours 12 minutes after the mission prompt, all ~100 BDD scenarios were green with 146/146 unit tests. John's total input in that window: six messages, one of which was "Continue."

## Phase 3: Overnight browser QA, and the harness eating its own tail (July 7, 20:59 to July 8, 12:36)

QA agents drove the running app in a real browser, and this is where the passing test suite started lying. At 02:11 on July 8, qa-834 caught the defining bug of the build: the schedule board's cleaner-reassign dropdown rendered outside any form, so "every real click on the reassign dropdown throws and silently no-ops. Confirmed via DB check: cleaner_id never changes." Meanwhile the story's own BDD specs all passed, because LiveView's `render_change/2` bypasses client JS entirely. The QA agent named it precisely: "false-positive green, worth flagging to whoever owns test strategy."

The multi-agent environment fought itself all night. Parallel QA agents shared one browser session ("every page I navigate to gets hijacked within milliseconds"). Any `mix compile` in a separate shell poisoned the dev server's build manifest; the server got bounced at least nine times in six hours. One QA agent worked around dead servers by starting extra instances, exhausted Postgres connections, and owned it: "I've stopped spinning up more instances since I'm contributing to the exhaustion, not just working around it."

John stepped in around 01:28 with fleet-level direction ("You should probably kill and then take a qa ticket to diagnose the problem"), and at 01:48 made the sharpest single catch of the build: "Oh shit, it's because we have a data-confirm, and it's completely untestable because it opens the native dialogue. We have to get rid of that and replace with modal. We did this in @../code_my_spec/". The agents had been flailing on flaky delete-button QA for hours; John recognized the pattern on sight. The agent did all the code work: component port, six call sites, two spec rewrites, back to green in minutes.

Then the ugliest stretch: at roughly 04:00 the CodeMySpec MCP server itself, the harness's own control plane, wedged and stayed effectively down for about 8.5 hours. Finished, verified QA work could not be submitted, and timed-out issue writes turned out to have landed server-side anyway. The orchestrator stopped 15 idle background tasks whose hooks kept re-wedging it, wrote status to disk, notified John by push, and downgraded to hourly probes: "Unchanged. Continuing the hourly probe (dropping the pointless restarts)." The app under construction sat green the entire time. The tool that built it was the thing that was broken.

QA still delivered through the chaos: stories 832 through 837 all passed or produced real findings, including a Stripe misconfiguration that crashed both charge paths and a Twilio config bug that could silently starve every account's reminders.

## Phase 4: Meltdown, the security hole, and 15 of 15 (July 8, 12:36 to 18:51)

The afternoon opened with a first-pass FAIL: story 838's pay types and rates existed in schema and logic but no UI anywhere could set them, so pay, totals, and CSV export were dead code from a user's perspective. Fixed in 12 minutes once filed.

Then the environment melted down again, differently. Assets started 404ing mid-QA, the login page 500ed, and arbitrary modules went "not available" on some requests but not others. The QA agent escalated correctly: "this reads as the running release having a partially-loaded/inconsistent code path, not something for me to route around." Root cause: two zombie phx.server processes squatting the port, serving stale partial builds while implementers recompiled underneath. The orchestrator's fix was a new discipline invented mid-run: serve QA from an immutable `mix release` copy, rebuilt after each fix batch, a pattern that held for the rest of the build. Cost of the outage: about 40 minutes, zero John involvement.

At 14:17 came the most important QA catch of the project: live QA found that `/schedule` and `/timesheets` had no role check at all: "qa-cleaner, a plain field cleaner, can reschedule/price-change/cancel/delete any job, create recurring plans, and view/export the whole account's payroll." Every spec was green. The fix landed in about 8 minutes and QA re-verified the redirect live.

By 15:52: "ALL 15 STORIES QA-PASSED in the browser." Five end-to-end journey QA runs followed, finding a checklist "Add Task" button that was a complete no-op in real browsers and a CSS selector bug affecting ~62% of UUIDs. Writing the Wallaby regression tests surfaced yet another real bug: recurring visits materialized with no price and crashed invoice generation. At 18:46 the requirement graph came back empty and the agent declared "The build is done", reporting that "every CodeMySpec requirement is satisfied, and the loop is stopped." Its own summary counted roughly 15 real bugs that specs alone missed.

## Phase 5: The demo and the missing customer (July 8, 19:20 to 23:12)

John asked for a demo: "Well bring up vibium and give me a demo then, show me everything." First friction: nothing appeared, because the browser had run headless for the entire build. Restarted visible, the agent toured the owner side and the cleaner side.

Then, at 19:31, the product review no gate had performed:

> "Damn, we didn't do a customer side did we? No public quotes?"

The system had built exactly what the prompt specified: two personas, owner and cleaner. No way for a customer to request a quote, book, pay, or leave a review. The research reports had actually flagged the customer surface as a market gap. Nobody, human or agent, had promoted that finding into scope. The harness was faithful to an under-specified prompt, and it declared itself done that way.

John's fix was one sentence at 19:33: "do the research on the customer side, leverage the jobber and housecall pro research if persisted, and add the stories, spex, and code for the customer side (quotes/payment/reviews/whatever else)." The pipeline that took most of two days for 15 stories replayed in one evening: research, a third persona (Cleaning Client), 6 new stories, validated architecture in 12 minutes; 43 red BDD specs by 20:11; three parallel implementation slices green by 21:15; QA verdicts landing by 21:57. QA immediately caught a validation hole in the new funnel: "I drove a lead all the way through payment confirmation with scheduled_date=2020-01-01 and it fully converted into a real 'scheduled' job." By 23:12 all six customer stories had passed, one verified across two real 15-minute Oban cron ticks.

## Phase 6: Ship it, then watch a stranger break it (July 9 to July 10)

July 9 was the shipping day: 16 commits total, the initial commit at 14:19 UTC and 15 more behind it. John's messages shifted to delegation and credentials. "Check @../devops/ and get us a uat deploy of this" produced a Kamal-on-Hetzner deployment in about 75 minutes, including three consecutive deploy failures, each self-diagnosed: the agent had wrongly stripped npm steps from the Dockerfile ("package.json existed all along", it admitted, "my earlier check was wrong"), then a missing health route, then `force_ssl` 301ing the health probe.

John's own live testing surfaced a lesson in error honesty: every booking failed with "That time was just booked by someone else," which was actually an unconfigured Stripe key mislabeled by a catch-all error clause. John: "Fuck dude should we set up a stripe sandbox for this?" The sandbox paid off within minutes; the first real charge caught a Live-adapter bug (`allow_redirects=never` required for server-side confirm) that the fake gateway and all 143 specs could never see.

At 19:49 John restructured the app by pointing at another repo: "Get all the owner app pages behind /app and in an app layout like @../get_ai_traffic/". One agent swept 166 files, all tests and specs green on its first report.

Then, at 21:42, John relayed a third-party tester's findings, prefaced with "I was a little obnoxious to test a few things." In roughly ten minutes of hostile clicking, the tester found what 36 QA passes had not: every quote combination returned "We can't price this yet" (John's own signup test had created an empty account that silently stole the public storefront, which the agent admitted was "a design flaw my earlier single-account assumption papered over"); `ThisManAteMySon@Fartmail.com` was accepted as a valid email; 1 square foot priced at $0.12 with the weekly discount; a 4,000-hour-per-week cleaning was bookable; and there was no payment field yet on the final step. Happy-path QA, even 36 rounds of it, is not adversarial QA. Three agents fixed, migrated, deployed, and browser-verified all findings in about 51 minutes.

The last act came after midnight. John: "Dude you need to get that form testable... you need to get that tested and recording with reqcassette." The resulting cassette-backed Stripe tests found a real security hole within 15 minutes: webhook signature verification had no timestamp tolerance, so a correctly signed payload from a year earlier was accepted. It had been live on UAT. The fix, plus a deploy regression the health check caught safely (a test-only dependency pin broke the production boot path; the old container kept serving), closed the build at 331 tests and 143 specs green, July 10, 01:25 UTC.

## What John actually did

Across roughly 2.5 days, John typed about 33 genuine messages. Per window, from the transcript mining:

- Day 1 build (4.5 hours): 6 messages. Five orchestration, one dependency pointer retracted 36 seconds later ("Actually I take that back, JediLuke's is fine"), which the agent had already solved independently.
- Overnight QA (14.5 hours): 6 messages. Two status pings, three orchestration, one root-cause insight.
- Day 2 QA through customer side (11 hours): about 5 messages plus one interrupt. Zero code-level.
- Deploy and hardening (27 hours): 16 messages. Nine orchestration (credentials, DNS, repo, unblocking), three product decisions, two quality directives, zero code-level corrections.

He never wrote or corrected a line of application code. His leverage concentrated at three altitudes: capacity ("got anything you can run in parallel?"), product judgment (the missing-persona catch, the UI pass, the Stripe sandbox call, the reqcassette mandate), and unblocking (AWS login, API keys, GitHub org, DNS).

Two honest asterisks keep that claim from being too clean. First, the data-confirm insight in Phase 3 was a genuine root-cause diagnosis from John, not an agent; the agents had burned hours around it. Second, the /app restructure was architecture direction, delivered by reference to another codebase rather than by hand, but still a human architectural decision the system had not proposed.

## The pattern

The specs were never the safety net they appeared to be. The load-bearing catches came from escalating realism: unit tests missed what browser QA caught (the reassign no-op, the missing role check, the untestable photo upload); browser QA missed what a hostile human caught (the $0.12 quote, the junk email, the storefront regression); and the fake payment gateway missed what real Stripe traffic caught (the adapter bug, the replay vulnerability). Each layer found real bugs within minutes of being added. The system's honest accounting of its own failures, in agents' own words ("my earlier check was wrong," "I'm contributing to the exhaustion," "I did not try to route around that block"), is what makes the passing numbers worth anything.
