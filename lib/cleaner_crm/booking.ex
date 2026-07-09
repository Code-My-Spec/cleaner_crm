defmodule CleanerCrm.Booking do
  @moduledoc """
  Public acquisition funnel (stories 848/849): the instant-quote
  calculator, capturing a lead's contact info once a price is shown,
  and quote acceptance — slot selection, cancellation-policy
  agreement, and Stripe card capture — that converts an accepted lead
  into a client + property + plan/job and issues portal access.

  Orchestrates `CleanerCrm.Quoting` (rate-card pricing, via
  `CleanerCrm.Booking.Pricing`), `CleanerCrm.Clients` (client +
  property), `CleanerCrm.Scheduling` (job/plan + slot availability),
  `CleanerCrm.Billing` (card capture via its `StripeGateway`), and
  `CleanerCrm.Portal` (the confirmation's magic-link).

  Every function here is either scoped by an explicit `Scope`
  (mirroring every other context) or takes a `CleanerCrm.Booking.Lead`
  directly and resolves its own account scope from it — none of them
  are reachable from a logged-in user, so there's no caller `Scope` to
  receive from a plug.

  ## Single-tenant storefront (known MVP limitation)

  `/book` carries no account identifier — no slug, no subdomain — so
  `public_scope/0` resolves to the *most recently created* account
  rather than *the right* one, matching the single-account assumption
  every story-848 spec drives (each spec's own account is the newest
  one the moment it hits `/book`, so this holds even alongside stray
  older rows). A multi-tenant deployment needs its own story to give
  each business a distinct public booking URL (e.g. `/book/:slug`)
  before this holds up outside a single-account deployment or test.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Accounts.Account
  alias CleanerCrm.Billing.StripeGateway
  alias CleanerCrm.Booking.{Lead, Notifier, Pricing}
  alias CleanerCrm.Clients
  alias CleanerCrm.Clients.Client
  alias CleanerCrm.Portal
  alias CleanerCrm.Quoting
  alias CleanerCrm.Quoting.RateCard
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.Scope

  # A reasonable number of visits to materialize up front for a
  # recurring booking, matching the office's own recurring-plan
  # builder default order of magnitude (see
  # `CleanerCrmWeb.ScheduleLive.PlanFormComponent`) — the office can
  # always add more from the schedule board afterward.
  @default_occurrence_count 12
  @default_visit_duration_seconds 2 * 60 * 60

  ## Public storefront

  @doc "The (single-account MVP) scope every unauthenticated booking-funnel call resolves against."
  def public_scope, do: %Scope{active_account_id: resolve_public_account_id()}

  @doc "The public rate card the instant-quote calculator prices against."
  def get_rate_card(%Scope{} = scope), do: Quoting.get_or_create_rate_card(scope)

  defp resolve_public_account_id do
    Account
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> select([a], a.id)
    |> Repo.one()
  end

  ## Instant quote (calculator)

  @doc """
  The calculator's live-preview changeset — never persisted, so the
  price can be computed before any contact info exists (see
  `quote_summary/2`).
  """
  def change_lead(%Lead{} = lead, attrs \\ %{}), do: Lead.quote_changeset(lead, attrs)

  @doc "Everything `CleanerCrmWeb.BookingLive.Quote` needs to render the live total."
  def quote_summary(%RateCard{} = rate_card, %Lead{} = lead),
    do: Pricing.summarize(rate_card, lead)

  @doc """
  Captures a visitor's contact info against their computed price —
  locking in the quote as an accepted lead with its own acceptance
  token, the moment `CleanerCrmWeb.BookingLive.Quote`'s contact form is
  submitted. Always saved as `:accepted`: a lead is only ever persisted
  once contact info makes it one.
  """
  def create_lead(%Scope{active_account_id: account_id}, attrs) when not is_nil(account_id) do
    %Lead{account_id: account_id}
    |> Lead.changeset(Map.merge(attrs, %{acceptance_token: generate_token(), status: :accepted}))
    |> Repo.insert()
  end

  @doc "Looks up an accepted lead by its public acceptance-link token. No `Scope` — the token is the access control."
  def get_lead_by_token(token) when is_binary(token),
    do: Repo.get_by(Lead, acceptance_token: token)

  defp generate_token, do: 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

  ## Acceptance: slot selection

  def change_slot(%Lead{} = lead, attrs \\ %{}), do: Lead.slot_changeset(lead, attrs)

  @doc """
  Validates and applies a slot choice to the (still unpersisted) lead
  — rejected outright if the chosen date/time is already in the past
  (see `Lead.slot_changeset/3`). Nothing reaches the database here —
  `confirm_booking/3` is the only place a slot gets written, so
  availability (and, per issue 4e985412, whether the slot is still in
  the future) is always checked again right before a card is ever
  charged, no matter how long a client lingers on the
  cancellation-policy step. `now` defaults to the real clock but takes
  an override for tests.
  """
  def select_slot(%Lead{} = lead, attrs, now \\ DateTime.utc_now()) do
    with {:ok, %Lead{start_time: start_time} = slotted} <-
           lead |> Lead.slot_changeset(attrs, now) |> Ecto.Changeset.apply_action(:update) do
      {:ok, %{slotted | end_time: default_end_time(start_time)}}
    end
  end

  defp default_end_time(start_time) do
    candidate = Time.add(start_time, @default_visit_duration_seconds, :second)
    if Time.compare(candidate, start_time) == :gt, do: candidate, else: ~T[23:59:59]
  end

  ## Acceptance: cancellation policy + payment

  def change_confirmation(%Lead{} = lead, attrs \\ %{}),
    do: Lead.confirmation_changeset(lead, attrs)

  @doc "Whether the lead's selected slot is still free, account-wide (single-crew capacity, not per-cleaner)."
  def slot_available?(%Lead{scheduled_date: nil}), do: false

  def slot_available?(%Lead{} = lead) do
    Scheduling.slot_available?(
      scope_for(lead),
      lead.scheduled_date,
      lead.start_time,
      lead.end_time
    )
  end

  @doc """
  The confirmation step. Refuses without charging anything when the
  cancellation policy isn't agreed to, the selected slot has already
  passed, or the slot's been claimed by another booking since it was
  selected — otherwise submits the card and moves the lead to
  `:payment_pending`. Only the Stripe webhook
  (`receive_payment_webhook/1`) ever confirms or declines it from
  there, per the same webhook-confirms-everything rule
  `CleanerCrm.Billing` follows for invoice payments.

  The past-slot check (issue 4e985412) is defense in depth alongside
  `Lead.slot_changeset/3`'s own form-level validation: a slot picked
  as "later today" can go stale by the time the client actually
  submits payment, the same reason `slot_available?/1` is re-checked
  here rather than trusted from selection time. `now` defaults to the
  real clock but takes an override for tests.
  """
  def confirm_booking(lead, params, now \\ DateTime.utc_now())

  def confirm_booking(%Lead{} = lead, %{"payment_method" => payment_method} = params, now) do
    cond do
      Map.get(params, "policy_agreed") not in [true, "true"] ->
        {:error, :policy_required}

      not Lead.slot_in_future?(lead, now) ->
        {:error, :slot_in_past}

      not slot_available?(lead) ->
        {:error, :slot_unavailable}

      true ->
        submit_payment(lead, payment_method)
    end
  end

  defp submit_payment(%Lead{} = lead, payment_method) when is_binary(payment_method) do
    with {:ok, %{id: intent_id}} <-
           StripeGateway.create_payment_intent(%{
             amount_cents: lead.total_cents,
             payment_method: payment_method,
             off_session: false,
             metadata: %{lead_id: lead.id}
           }) do
      lead
      |> Lead.changeset(%{
        policy_agreed_at: DateTime.utc_now(),
        status: :payment_pending,
        stripe_payment_intent_id: intent_id
      })
      # `select_slot/2` never touches the database (see its doc) — the
      # slot lives only on this in-memory `lead` struct until now, so
      # `cast/3` (which diffs against the struct's own field, not the
      # row) would otherwise see "no change" and silently leave the
      # database's scheduled_date/start_time/end_time at `nil`.
      |> Ecto.Changeset.force_change(:scheduled_date, lead.scheduled_date)
      |> Ecto.Changeset.force_change(:start_time, lead.start_time)
      |> Ecto.Changeset.force_change(:end_time, lead.end_time)
      |> Repo.update()
    end
  end

  ## Webhook

  @doc """
  Verifies and applies an inbound Stripe webhook request for a
  booking's payment — `CleanerCrmWeb.StripeWebhookController` falls
  back to this once `CleanerCrm.Billing.receive_webhook/1` reports the
  event isn't one of its own invoices.
  """
  def receive_payment_webhook(conn) do
    with {:ok, event} <- StripeGateway.verify_webhook_event(conn) do
      apply_webhook_event(event)
    end
  end

  defp apply_webhook_event(%{"type" => "payment_intent.succeeded"} = event) do
    with {:ok, lead} <- find_lead_for_event(event) do
      convert_lead(lead)
    end
  end

  defp apply_webhook_event(%{"type" => "payment_intent.payment_failed"} = event) do
    with {:ok, lead} <- find_lead_for_event(event) do
      decline_lead(lead)
    end
  end

  defp apply_webhook_event(%{"type" => _other}), do: {:error, :lead_not_found}

  defp find_lead_for_event(%{"data" => %{"object" => object}}) do
    case object do
      %{"metadata" => %{"lead_id" => lead_id}} when is_binary(lead_id) -> fetch_lead(lead_id)
      %{"id" => intent_id} when is_binary(intent_id) -> fetch_lead_by_intent(intent_id)
      _ -> {:error, :lead_not_found}
    end
  end

  defp fetch_lead(lead_id) do
    case Repo.get(Lead, lead_id) do
      nil -> {:error, :lead_not_found}
      lead -> {:ok, lead}
    end
  end

  defp fetch_lead_by_intent(intent_id) do
    case Repo.get_by(Lead, stripe_payment_intent_id: intent_id) do
      nil -> {:error, :lead_not_found}
      lead -> {:ok, lead}
    end
  end

  defp decline_lead(%Lead{} = lead) do
    lead |> Lead.changeset(%{status: :payment_declined}) |> Repo.update()
  end

  # Idempotent against a redelivered webhook — Stripe (and its Test
  # stand-in) offers no stronger delivery guarantee than at-least-once.
  defp convert_lead(%Lead{status: :converted} = lead), do: {:ok, lead}

  defp convert_lead(%Lead{} = lead) do
    scope = scope_for(lead)

    with {:ok, {updated, client}} <-
           Repo.transact(fn ->
             with {:ok, client} <- Clients.create_client(scope, client_attrs(lead)),
                  {:ok, property} <- Clients.create_property(scope, property_attrs(client)),
                  {:ok, visit_ids} <- schedule_visit(scope, lead, property),
                  {:ok, updated} <- finalize_conversion(lead, client, property, visit_ids) do
               {:ok, {updated, client}}
             end
           end) do
      issue_portal_access(updated, client)
      {:ok, updated}
    end
  end

  defp client_attrs(%Lead{} = lead) do
    %{
      name: lead.client_name,
      email: lead.client_email,
      phone: lead.client_phone,
      card_on_file: true
    }
  end

  # No property inputs exist anywhere in the public funnel (story 848's
  # form only ever asks for what prices the job) — the office fills
  # the real address in from the client record afterward. Named after
  # the client rather than a generic placeholder so the schedule board
  # (which shows a job's property, never its client, on the card) still
  # identifies whose visit this is until that happens.
  defp property_attrs(%Client{} = client) do
    %{client_id: client.id, service_address: "#{client.name} — address to be confirmed"}
  end

  defp schedule_visit(scope, %Lead{frequency: :one_time} = lead, property) do
    with {:ok, job} <-
           Scheduling.create_job(scope, %{
             property_id: property.id,
             scheduled_date: lead.scheduled_date,
             start_time: lead.start_time,
             end_time: lead.end_time,
             agreed_price_cents: lead.total_cents,
             status: :scheduled
           }) do
      {:ok, %{job_id: job.id, recurring_plan_id: nil}}
    end
  end

  defp schedule_visit(scope, %Lead{} = lead, property) do
    with {:ok, {plan, _jobs}} <-
           Scheduling.create_recurring_plan(scope, %{
             property_id: property.id,
             recurrence: lead.frequency,
             start_date: lead.scheduled_date,
             occurrence_count: @default_occurrence_count,
             start_time: lead.start_time,
             end_time: lead.end_time,
             agreed_price_cents: lead.total_cents
           }) do
      {:ok, %{job_id: nil, recurring_plan_id: plan.id}}
    end
  end

  defp finalize_conversion(%Lead{} = lead, %Client{} = client, property, visit_ids) do
    lead
    |> Lead.changeset(
      Map.merge(%{status: :converted, client_id: client.id, property_id: property.id}, visit_ids)
    )
    |> Repo.update()
  end

  defp issue_portal_access(%Lead{} = lead, %Client{} = client) do
    with {:ok, session} <- Portal.create_portal_session(client, %{}) do
      Notifier.deliver_confirmation(lead, portal_url(session))
    end
  end

  # `CleanerCrmWeb.Endpoint.url()` is the standard phx.gen.auth-style
  # exception for building absolute links in outbound messages — see
  # the `dirty_xrefs` note on the `CleanerCrm` boundary.
  defp portal_url(session), do: CleanerCrmWeb.Endpoint.url() <> "/portal/access/#{session.token}"

  defp scope_for(%Lead{account_id: account_id}), do: %Scope{active_account_id: account_id}
end
