defmodule CleanerCrmSpex.Fixtures do
  @moduledoc """
  Curated bridge from BDD specs into in-app state.

  The only module that may dep on `CleanerCrm` from inside the spex test
  tree. Declared as its own top-level Boundary so the spec boundary
  (`CleanerCrmSpex`) can dep on it without inheriting `CleanerCrm`'s deps.

  Keep this list small — every export is a sanctioned shortcut past the
  UI, used only for `given_` state that has its own covered creation flow.
  """

  use Boundary, top_level?: true, deps: [CleanerCrm, CleanerCrmTest]

  # These contexts are specified in the architecture but not yet
  # implemented — the red BDD specs that call these fixtures exist to
  # drive their implementation. Remove entries as each context lands.
  @compile {:no_warn_undefined,
            [
              CleanerCrm.Clients,
              CleanerCrm.Scheduling,
              CleanerCrm.Booking,
              CleanerCrm.Portal,
              CleanerCrm.Reviews
            ]}

  # Auth/session seeding — registration and login have their own specs;
  # every other spec starts from an existing confirmed user.
  defdelegate user_fixture(attrs \\ %{}), to: CleanerCrm.UsersFixtures
  defdelegate unconfirmed_user_fixture(attrs \\ %{}), to: CleanerCrm.UsersFixtures
  defdelegate user_scope_fixture(), to: CleanerCrm.UsersFixtures
  defdelegate user_scope_fixture(user), to: CleanerCrm.UsersFixtures
  defdelegate valid_user_password(), to: CleanerCrm.UsersFixtures
  defdelegate set_password(user), to: CleanerCrm.UsersFixtures

  # Tenant seeding — account creation has its own spec; other specs need
  # an existing company (account) to scope against.
  # Uncertain export: prune if account specs end up seeding via the UI.
  def account_fixture(scope, attrs \\ %{}) do
    {:ok, account} =
      CleanerCrm.Accounts.create_account(
        scope,
        Enum.into(attrs, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})
      )

    account
  end

  # Session — logs a fixture user into a conn. Login itself has its
  # own auth specs; every other spec starts from an authenticated conn.
  defdelegate log_in_user(conn, user), to: CleanerCrmTest.ConnCase

  # Scheduling (story 834) — a cleaner is an account member who gets
  # assigned jobs. No creation flow covers this yet: `ScheduleLive.Board`
  # (the board's own assign/reassign UI) doesn't exist. Sanctioned
  # bypass per bdd/spex/boundaries.md — prune once the board can seed
  # cleaner assignment directly.
  def cleaner_fixture(scope, account, attrs \\ %{}) do
    # `CleanerCrm.Users.register_user/1` (which `user_fixture/1` goes
    # through) only ever casts `:email` and `:push_enabled` — the
    # standard phx.gen.auth registration changeset has no `:name`
    # field, so a `name:` in `attrs` would otherwise be silently
    # dropped. Set it directly here the same way
    # `CleanerCrm.Scheduling.register_cleaner/2` does for its own
    # (real, non-fixture) cleaner-creation path.
    user = attrs |> Map.delete(:name) |> CleanerCrm.UsersFixtures.user_fixture()
    user = maybe_set_name(user, attrs)
    {:ok, _member} = CleanerCrm.Accounts.add_user_to_account(scope, user.id, account.id, :member)
    user
  end

  defp maybe_set_name(user, %{name: name}) do
    user
    |> Ecto.Changeset.cast(%{name: name}, [:name])
    |> CleanerCrm.Repo.update!()
  end

  defp maybe_set_name(user, _attrs), do: user

  # Billing (story 836) — client, job, and invoice seeding.
  #
  # Job completion generating its invoice is covered end-to-end by
  # story 836's own "completing a job generates its invoice" spec
  # (drives FieldLive.Job -> InvoiceLive). Scenarios whose subject is
  # a downstream invoice-collection decision (charging a card,
  # payment links, declines, webhook confirmation) seed the completed
  # job and its invoice directly here instead of re-driving job
  # completion every time — a sanctioned shortcut per
  # bdd/spex/boundaries.md.
  def client_fixture(scope, attrs \\ %{}) do
    {:ok, client} =
      CleanerCrm.Clients.create_client(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          name: "Client #{System.unique_integer([:positive])}",
          card_on_file: false,
          email: "client#{System.unique_integer([:positive])}@example.com",
          phone: "+15555550100"
        })
      )

    client
  end

  def job_fixture(scope, client, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    start_time = Map.get(attrs, :start_time, ~T[09:00:00])

    {:ok, job} =
      CleanerCrm.Scheduling.create_job(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          client_id: client.id,
          agreed_price: Decimal.new("150.00"),
          status: :scheduled,
          scheduled_date: Date.add(Date.utc_today(), 7),
          start_time: start_time,
          # Some specs override `start_time` alone (e.g. pinning it to a
          # lead-time boundary) without overriding `end_time` — a fixed
          # `~T[11:00:00]` default would then land before an overridden
          # start_time and fail the "end after start" changeset check.
          end_time: default_end_time(start_time)
        })
      )

    # Notifications (story 837) — the automatic reminder trigger is a
    # periodic Oban-cron scan in production (see the background-jobs
    # ADR); nothing about creating a job through this fixture would
    # otherwise run that scan within a spec's lifetime. Running it here
    # is a no-op for every job outside its owning account's configured
    # lead-time window (and a no-op entirely for accounts that never
    # configured reminders), so it's safe for every other story's jobs
    # while making story 837's own boundary-timed fixtures deterministic.
    CleanerCrm.Notifications.send_due_reminders()

    job
  end

  # `given_` blocks bind `scope` from `user_scope_fixture/1` *before*
  # `account_fixture/2` creates the account, so it never carries an
  # `active_account_id` — every fixture below that scopes a context
  # call by account needs to resolve it from the user's membership at
  # call time instead of trusting the scope it was handed.
  defp scoped_to_account(%CleanerCrm.Users.Scope{active_account_id: nil, user: user} = scope) do
    case CleanerCrm.Accounts.MembersRepository.list_user_accounts(user.id) do
      [account | _] -> %{scope | active_account_id: account.id, active_account: account}
      [] -> scope
    end
  end

  defp scoped_to_account(scope), do: scope

  # Two hours after `start_time`, unless that would wrap past midnight
  # (into an earlier clock time), in which case the day just ends there.
  defp default_end_time(start_time) do
    candidate = Time.add(start_time, 2 * 3600, :second)
    if Time.compare(candidate, start_time) == :gt, do: candidate, else: ~T[23:59:59]
  end

  def job_with_proof_of_work_fixture(scope, client, attrs \\ %{}) do
    scope = scoped_to_account(scope)
    job = job_fixture(scope, client, Enum.into(attrs, %{status: :completed}))

    {:ok, _checklist} =
      CleanerCrm.Quality.complete_checklist(scope, job, [
        %{
          task: "Kitchen counters wiped down",
          before_photo: "before_kitchen.jpg",
          after_photo: "after_kitchen.jpg"
        },
        %{
          task: "Bathrooms sanitized",
          before_photo: "before_bath.jpg",
          after_photo: "after_bath.jpg"
        }
      ])

    job
  end

  def invoice_fixture(scope, job, attrs \\ %{}) do
    {:ok, invoice} =
      CleanerCrm.Billing.create_invoice(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          job_id: job.id,
          amount: job.agreed_price,
          status: :unpaid
        })
      )

    invoice
  end

  # Time tracking (story 838) — a resolved clock-in/out record for a
  # job.
  #
  # Clocking in and out through the UI is covered end-to-end by story
  # 838's own "cleaner clocks in and out of an assigned job" spec
  # (drives FieldLive.Job). Scenarios whose subject is a downstream pay
  # calculation (hourly vs. piece-rate, running pay-period totals,
  # payroll CSV export) seed the resolved time entry directly here
  # instead of re-driving the clock-in/out flow every time — a
  # sanctioned shortcut per bdd/spex/boundaries.md.
  def time_entry_fixture(scope, job, attrs \\ %{}) do
    {:ok, time_entry} =
      CleanerCrm.TimeTracking.create_time_entry(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          job_id: job.id,
          clocked_in_at: ~U[2024-01-08 09:00:00Z],
          clocked_out_at: ~U[2024-01-08 12:00:00Z]
        })
      )

    time_entry
  end

  # Notifications (story 837) — an already-sent appointment reminder
  # with its confirm/reschedule token.
  #
  # The automatic "reminder sent at the configured lead time" trigger
  # is covered end-to-end by story 837's own "reminder fires at the
  # configured lead time" spec. Scenarios whose subject is a
  # downstream decision on an existing reminder (confirm, reschedule,
  # delivery-status fallback) seed the already-sent notification
  # directly here instead of re-driving the scheduler trigger every
  # time — a sanctioned shortcut per bdd/spex/boundaries.md.
  def notification_fixture(scope, client, job, attrs \\ %{}) do
    {:ok, notification} =
      CleanerCrm.Notifications.create_notification(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          client_id: client.id,
          job_id: job.id,
          kind: :reminder,
          channel: :email,
          status: :sent,
          token: "reminder_token_#{System.unique_integer([:positive])}"
        })
      )

    notification
  end

  # Schedule alerts (story 843) — a pending schedule-change
  # notification already pushed to a cleaner.
  #
  # The push itself (a moved or cancelled job creating this
  # notification) is covered end-to-end by story 843's own "moved job
  # notifies the cleaner" / "cancelled job notifies the cleaner"
  # specs, which drive the real trigger via `ScheduleLive.Board`.
  # Scenarios whose subject is a downstream decision on an existing
  # pending change (acknowledging, re-prompting, office visibility,
  # escalation, channel fallback) seed the already-pushed notification
  # directly here instead of re-driving the board move every time — a
  # sanctioned shortcut per bdd/spex/boundaries.md. Never pass
  # `status: :acknowledged` here — the acknowledgment round-trip
  # through `FieldLive.Today` is the whole point of story 843.
  def schedule_change_notification_fixture(scope, cleaner, job, attrs \\ %{}) do
    {:ok, notification} =
      CleanerCrm.Notifications.create_notification(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          cleaner_id: cleaner.id,
          job_id: job.id,
          kind: :schedule_change,
          channel: :push,
          status: :pending,
          change_summary: "Job schedule changed",
          pushed_at: DateTime.utc_now(),
          token: "schedule_change_token_#{System.unique_integer([:positive])}"
        })
      )

    notification
  end

  # Quality (story 839) — a job carrying an unfinished, per-job
  # checklist of required and optional tasks.
  #
  # Checking items off and completing the job through the checklist UI
  # is the subject under test in `FieldLive.Job`, so this fixture stops
  # short of that — it only seeds the checklist itself. Sanctioned
  # bypass per bdd/spex/boundaries.md: `ChecklistTemplate` assignment
  # (story 842) has its own creation flow this fixture skips.
  def job_with_checklist_fixture(scope, client, cleaner, attrs \\ %{}) do
    scope = scoped_to_account(scope)

    job =
      job_fixture(
        scope,
        client,
        Enum.into(attrs, %{status: :in_progress, cleaner_id: cleaner.id})
      )

    {:ok, checklist} =
      CleanerCrm.Quality.create_checklist(scope, job, [
        %{task: "Kitchen counters wiped down", required: true},
        %{task: "Bathrooms sanitized", required: true},
        %{task: "Fridge interior wiped down", required: false}
      ])

    %{job: job, checklist: checklist}
  end

  # Quality (story 842) — a job carrying an unfinished, room-grouped
  # checklist whose items are exactly what the caller passes in.
  #
  # Story 842 owns the `ChecklistTemplate` -> per-job `Checklist`
  # assignment flow (which room/task combinations count as in scope for
  # a given job). That assignment UI doesn't exist yet and isn't part
  # of this story's component list (only `FieldLive.ChecklistComponent`
  # is), so seeding the already-instantiated, room-tagged checklist
  # directly is the sanctioned bypass per bdd/spex/boundaries.md — the
  # subject under test is opening/working the checklist on
  # `FieldLive.Job`, not how it got assigned. `items` is a list of
  # `%{room:, task:, required:}` maps; a spec proving an out-of-scope
  # task never appears simply omits it from `items`.
  def job_with_room_checklist_fixture(scope, client, cleaner, items, attrs \\ %{}) do
    scope = scoped_to_account(scope)

    job =
      job_fixture(
        scope,
        client,
        Enum.into(attrs, %{status: :in_progress, cleaner_id: cleaner.id})
      )

    {:ok, checklist} = CleanerCrm.Quality.create_checklist(scope, job, items)

    %{job: job, checklist: checklist}
  end

  # Client portal (stories 851, 852) — an already-established client
  # portal session.
  #
  # The magic-link exchange itself (`/portal/access/:token`) is covered
  # end-to-end by story 850's own specs. Downstream portal stories
  # whose subject is what a client can do once inside the portal seed
  # the session directly here instead of re-driving that exchange
  # every time — a sanctioned shortcut per bdd/spex/boundaries.md.
  # Assumes `CleanerCrmWeb.PortalAuth` reads the client id from the
  # `:portal_client_id` session key (mirroring `:user_token` for staff
  # auth).
  def portal_session_fixture(client) do
    Phoenix.ConnTest.build_conn()
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:portal_client_id, client.id)
  end

  # Reschedule/cancel policy (story 851) — the account's configured
  # notice window and fees.
  #
  # The client-facing decision (on-time, late, or same-day) is the
  # subject under test, so this only seeds the account's stated
  # policy, never a per-job fee outcome.
  def cancellation_policy_fixture(scope, attrs \\ %{}) do
    {:ok, policy} =
      CleanerCrm.Scheduling.set_cancellation_policy(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          notice_window_hours: 48,
          late_fee_cents: 2_500,
          same_day_fee_cents: 5_000
        })
      )

    policy
  end

  # Quoting (story 848) — the account's public-facing rate card, set
  # directly rather than through the office `QuoteLive.Builder` rate
  # card form (covered end-to-end by story 835) since these specs'
  # subject is the public instant-quote calculator reading it, not the
  # office save flow. Extra keys the current `RateCard` schema doesn't
  # persist yet (frequency discounts, add-on pricing) are accepted
  # here so specs can drive the pricing config story 848 needs once
  # the schema grows to hold it.
  def rate_card_fixture(scope, attrs \\ %{}) do
    scope = scoped_to_account(scope)
    rate_card = CleanerCrm.Quoting.get_or_create_rate_card(scope)
    {:ok, rate_card} = CleanerCrm.Quoting.update_rate_card(scope, rate_card, attrs)
    rate_card
  end

  # Booking (story 849) — an instant quote already accepted by the
  # client (contact captured, price locked). The quote-to-accepted
  # transition itself is covered end-to-end by story 848's own
  # "instant quote price matches the later acceptance total" spec, so
  # scenarios whose subject is the slot/policy/card steps that follow
  # seed the accepted lead directly here instead of re-driving the
  # quote calculator every time — a sanctioned shortcut per
  # bdd/spex/boundaries.md.
  def lead_fixture(scope, attrs \\ %{}) do
    {:ok, lead} =
      CleanerCrm.Booking.create_lead(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          pricing_model: :per_room,
          bedroom_count: 3,
          bathroom_count: 2,
          frequency: :one_time,
          total_cents: 19_500,
          status: :accepted,
          client_name: "Dana Prescott",
          client_email: "dana-#{System.unique_integer([:positive])}@example.com",
          client_phone: "+15555550100"
        })
      )

    lead
  end

  # Portal (story 850) — an already-issued, not-yet-exchanged
  # magic-link token for a client, distinct from `portal_session_fixture/1`
  # above (which bypasses straight to an established session for
  # downstream stories 851/852). This one's subject is the token
  # exchange itself — validity and expiry — so it hands back the raw
  # session/token record rather than a conn already carrying it.
  def portal_magic_link_fixture(client, attrs \\ %{}) do
    {:ok, session} = CleanerCrm.Portal.create_portal_session(client, Enum.into(attrs, %{}))
    session
  end

  # Reviews (story 853) — an already-sent review request for a
  # completed visit, distinct from the thank-you/request send itself
  # (covered end-to-end by criteria 7244/7245's own specs). Scenarios
  # whose subject is what happens once the client reaches
  # `ReviewLive.Public` (rating routing, no-duplicate-request) seed
  # the already-requested review directly here instead of re-driving
  # the completion-to-request pipeline every time — a sanctioned
  # shortcut per bdd/spex/boundaries.md.
  def review_request_fixture(scope, job, client, attrs \\ %{}) do
    {:ok, review} =
      CleanerCrm.Reviews.create_review(
        scoped_to_account(scope),
        Enum.into(attrs, %{
          job_id: job.id,
          client_id: client.id,
          status: :review_requested,
          token: "review_token_#{System.unique_integer([:positive])}",
          review_request_sent_at: DateTime.utc_now()
        })
      )

    review
  end

  # Reviews (story 853) — runs the periodic review-request scan now,
  # exactly as `CleanerCrm.Reviews.ReviewScheduler.perform/1` does on
  # its Oban cron schedule (mirrors `send_due_reminders/0` above for
  # story 837's reminder scan). `as_of` lets a spec assert the
  # ~24h-later trigger without backdating any row's own timestamp —
  # the same injectable "now" seam `ReminderScheduler.scan_and_send/1`
  # already uses.
  def run_due_review_requests(as_of \\ DateTime.utc_now()) do
    CleanerCrm.Reviews.send_due_review_requests(as_of)
  end
end
