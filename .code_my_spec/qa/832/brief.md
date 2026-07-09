# Qa Story Brief

Story 832 — Manage clients and properties with access details

## Tool

web

## Auth

Log in as the owner via the browser (this story's surfaces — `/clients`,
`/properties/*`, `/schedule` — are all under `:require_authenticated_user`,
so use Vibium MCP browser tools, never curl with cookies).

1. `browser_launch(headless: true)`
2. `browser_navigate(url: "http://127.0.0.1:4100/users/log-in")`
3. `browser_scroll_into_view(selector: "#login_form_password")`
4. `browser_fill(selector: "input[name=\"user[email]\"]", value: "qa-owner@cleanercrm.test")`
5. `browser_fill(selector: "input[name=\"user[password]\"]", value: "qa password 1234")`
6. Click the password form's submit button ("Log in" inside `#login_form_password`)
7. `browser_wait_for_url(pattern: "/")` — success redirects to `/`

Cleaner login (only needed if a cleaner-vs-owner permission check comes up):
`qa-cleaner@cleanercrm.test` / `qa password 1234`, same form.

## Seeds

```
mix run priv/repo/qa_seeds.exs
```

Idempotent. Creates owner `qa-owner@cleanercrm.test`, cleaner
`qa-cleaner@cleanercrm.test` (both password `qa password 1234`), and account
"QA Sparkle Cleaning Co". No clients/properties/jobs are pre-seeded by this
script — create them live during the test scenarios below using the app's
own forms (each scenario is self-contained and creates its own client).

## What To Test

Routes (confirmed in `lib/cleaner_crm_web/router.ex`): `/clients`,
`/clients/new`, `/clients/:id`, `/clients/:id/edit`,
`/clients/:id/properties/new`, `/properties/new`, `/properties/:id`,
`/properties/:id/edit`, `/schedule`.

- **Add a property under an existing client** (criterion 7107): create
  client "Sarah Kim" via `/clients/new` (`[data-test='client-form']`,
  field `client[name]`) → submit → redirects to `/clients/:id`. From
  there click "Add Property" → `/clients/:id/properties/new`. Fill
  `[data-test='property-form']` field `property[service_address]` =
  "123 Oak St" → submit. Expect redirect to `/properties/:id`. Verify the
  client's show page (`/clients/:id`) lists "123 Oak St". Verify the
  property page shows `[data-test='property-client']` containing "Sarah
  Kim" exactly once (no client picker shown, since client was
  preselected from this route).

- **Reject a property with no client** (criterion 7108): navigate
  directly to `/properties/new` (no client preselected — a client
  `<select>` should render). Fill only
  `property[service_address]` = "123 Oak St", leave the client select
  unset, submit. Expect the form stays on the page (no navigation) and
  `[data-test='client-error']` shows text containing "is required".

- **Save a property with a valid service address** (criterion 7109):
  create client "Priya Nair", go to its "add property" form, fill
  `property[service_address]` = "123 Oak St, Austin, TX", submit.
  Expect redirect to `/properties/:id` and the page shows "123 Oak St,
  Austin, TX".

- **Reject a property with a blank address** (criterion 7110): on the
  same "add property" form (client preselected), leave
  `property[service_address]` blank, submit. Expect the form stays put
  and `[data-test='service-address-error']` shows text containing "is
  required".

- **Job brief inherits property access details** (criterion 7111):
  create client "Devon Ashe", add a property "77 Maple Ave" with
  `property[lockbox_code]` = "4821", `property[parking_notes]` =
  "driveway only", `property[pet_notes]` = "dog in yard" (also fill
  `property[entry_method]` if you want extra coverage — not required by
  the criterion). Go to `/schedule`, click
  `[data-test='new-job-button']`, fill the job form (`job[property_id]`
  = the 77 Maple Ave property via its select option, and the date field
  named `job[date]` — use a date 7+ days out, e.g. today + 7 days in
  `YYYY-MM-DD`), submit. Expect the schedule board / job card to show
  "77 Maple Ave", "4821", "driveway only", and "dog in yard" (the job
  brief).

- **Updated code propagates to future jobs** (criterion 7113): create
  client "Jordan Lee", property "45 Elm St" with `lockbox_code` =
  "4821", schedule a job on it dated 7+ days out (same flow as above).
  Then go to `/properties/:id/edit` for that property, change
  `property[lockbox_code]` to "9077", submit (redirects back to the
  property page). Return to `/schedule` and confirm the job card for
  "45 Elm St" now shows "9077" and does **not** show "4821" anywhere.

- **Entry code change is logged** (criterion 7115): create client "Alex
  Rivera", property "12 Cedar Ct" with `property[alarm_code]` = "1234".
  Edit the property (`/properties/:id/edit`), change
  `property[alarm_code]` to "5678", submit. On the property's show page,
  confirm a heading/section "Access Change History" appears, with a
  `[data-test='audit-entry']` row containing the owner's email
  (`qa-owner@cleanercrm.test`) and the text "alarm code", and that the
  entry element carries a `data-timestamp` attribute (inspect via
  `browser_get_attribute` or `browser_get_html`).

- **Deactivate a client with upcoming jobs** (criterion 7117): create
  client "Morgan Reyes", property "9 Birch Ln", schedule a job 7+ days
  out. On `/clients/:id` click `[data-test='deactivate-client-button']`
  (confirm the native `data-confirm` dialog via
  `browser_dialog_accept` if one appears). Expect the client's header
  now shows "Inactive". Go to `/clients` and confirm "Morgan Reyes" does
  **not** appear in the active list. Return to `/clients/:id` directly
  and confirm the client's name "Morgan Reyes" and its property "9 Birch
  Ln" are still shown (history/properties retained despite being
  hidden from the active index).

- **Block hard delete of a client with upcoming jobs** (criterion
  7118): create client "Taylor Brooks", property "3 Willow Way",
  schedule a job 7+ days out. On `/clients/:id` click
  `[data-test='delete-client-button']` (accept the confirm dialog).
  Expect deletion is blocked: a flash/error message mentioning
  "deactivate" and "upcoming job(s)" appears, and the client still
  exists — check `/clients` (if still active) or `/clients/:id` shows
  "Taylor Brooks" still present, not deleted.

- **Exploratory (not a numbered criterion but worth a quick check):**
  the client form (`[data-test='client-form']`) also has a
  `client[card_on_file]` checkbox — confirm it doesn't block a plain
  name-only submit. On `/clients/new`, submitting a blank name should
  presumably error too — try it and note actual behavior even though
  it's not an explicit acceptance criterion.

## Result Path

No result.md file — file findings via `create_issue` as discovered and
call `mcp__plugin_codemyspec_local__submit_qa_result` with
`task_id: e4939525-62c6-4611-9e1f-04207dea11ba` at the end. Save
screenshots to `.code_my_spec/qa/832/screenshots/`.

## Setup Notes

- All property/client/schedule pages are LiveViews under
  `CleanerCrmWeb.ClientLive.Show` (`/clients/:id`, `/properties/:id`,
  edit variants) and `CleanerCrmWeb.ClientLive.Index` (`/clients`),
  `CleanerCrmWeb.ScheduleLive.Index` (`/schedule`) — confirmed by
  reading `lib/cleaner_crm_web/live/client_live/show.ex`,
  `lib/cleaner_crm_web/live/client_live/property_form_component.ex`, and
  `lib/cleaner_crm_web/live/schedule_live/job_form_component.ex`. Use
  those files if a selector below doesn't match what's rendered.
- The property form's client `<select>` only renders when no client is
  preselected (`/properties/new`); from a client's own page
  (`/clients/:id/properties/new`) the client is fixed and hidden.
- The job form's date input is a real `<input type="date">` bound to
  `job[date]` (not `job[scheduled_date]`, which is a hidden decoy field
  in the markup) — fill the visible date input by its label "Date" or
  by id, not by name, to avoid the hidden field.
- Each scenario above creates its own client — this avoids cross-test
  interference and mirrors the BDD spex fixtures at
  `test/spex/832_manage_clients_and_properties_with_access_details/`.
