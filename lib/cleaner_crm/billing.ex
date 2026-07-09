defmodule CleanerCrm.Billing do
  @moduledoc """
  Invoices generated from completed jobs and payment collection via
  card-on-file or a public payment link, with proof-of-work attached
  from `CleanerCrm.Quality` for chargeback defense.

  Per the payments-stripe ADR, an invoice's `status` only ever advances
  on a Stripe webhook confirmation: `charge_card/2` and
  `pay_via_link/2` just submit a PaymentIntent and move the invoice to
  `:charge_pending`; only `receive_webhook/1` marks it `:paid`, or
  reverts it to `:unpaid` on a decline so the owner can retry or send a
  payment link.

  Every function that isn't reached from the public `/pay/:token` or
  `/webhooks/stripe` routes is scoped to the caller's active account —
  those two have no logged-in user to scope against.

  ## Job completion integration point

  No caller generates an invoice automatically yet: job completion
  itself lives in `CleanerCrm.Quality.complete_job/2`
  (`CleanerCrmWeb.FieldLive.Job`, which will drive it, doesn't exist
  yet either). Once it does, the natural hook is right there — call
  `generate_for_job/2` with the now-completed job after
  `Quality.complete_job/2` succeeds.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Billing.{Invoice, Payment, ReceiptNotifier, StripeGateway}
  alias CleanerCrm.Clients.Client
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.Users.Scope

  ## Invoices

  @doc "Lists the account's invoices, most recent first, for the billing queue."
  def list_invoices(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    Invoice
    |> where([i], i.account_id == ^account_id)
    |> order_by([i], desc: i.inserted_at)
    |> preload(job: :client)
    |> Repo.all()
  end

  def get_invoice!(%Scope{active_account_id: account_id}, id) when not is_nil(account_id) do
    Invoice
    |> where([i], i.account_id == ^account_id)
    |> preload(job: :client)
    |> Repo.get!(id)
  end

  @doc """
  Looks up an invoice by its public payment-link token. Takes no
  `Scope` — the payer on `/pay/:token` isn't a logged-in user, so the
  token itself (unguessable, unique) is the only access control this
  lookup has.
  """
  def get_invoice_by_token(token) when is_binary(token) do
    Invoice
    |> where([i], i.payment_token == ^token)
    |> preload(job: :client)
    |> Repo.one()
  end

  def create_invoice(%Scope{active_account_id: account_id}, attrs) when not is_nil(account_id) do
    %Invoice{account_id: account_id}
    |> Invoice.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Generates the invoice for a job that's just been marked complete —
  see the moduledoc for where this gets wired in once job completion
  has a real caller.

  Returns `{:error, :no_price}` without creating an invoice, and
  without touching the database at all, when the job has no
  `agreed_price_cents` — e.g. a visit materialized from a
  `CleanerCrm.Scheduling.RecurringPlan` with no price set (see
  `CleanerCrm.Scheduling.Recurrence.job_attrs/1`). Job completion itself
  must still succeed in that case, so callers should let this error
  through rather than fail the completion on it. There's no dedicated
  "completed jobs missing an invoice" queue today — the office notices
  a missing invoice by comparing the schedule board's completed jobs
  against `list_invoices/1`, or avoids it entirely by pricing the job
  (or its recurring plan) before it's completed.
  """
  def generate_for_job(%Scope{}, %Job{agreed_price_cents: nil}), do: {:error, :no_price}

  def generate_for_job(%Scope{} = scope, %Job{} = job) do
    create_invoice(scope, %{job_id: job.id, amount_cents: job.agreed_price_cents, status: :unpaid})
  end

  ## Payment collection

  @doc """
  Charges the client's card on file for the invoice's full amount.
  Refused with `{:error, :no_card_on_file}` when the client has none.
  """
  def charge_card(
        %Scope{active_account_id: account_id},
        %Invoice{account_id: account_id} = invoice
      )
      when not is_nil(account_id) do
    invoice
    |> invoice_client()
    |> submit_and_finalize_charge(invoice, off_session: true, source: "card_on_file")
  end

  defp submit_and_finalize_charge(%Client{card_on_file: false}, _invoice, _opts),
    do: {:error, :no_card_on_file}

  defp submit_and_finalize_charge(%Client{} = client, invoice, opts) do
    {source, charge_opts} = Keyword.pop!(opts, :source)

    with {:ok, %{id: intent_id}} <-
           submit_charge(invoice, payment_method_for(client), charge_opts) do
      finalize_charge_submission(invoice, client, intent_id, source)
    end
  end

  @doc """
  Charges the given payment method against the invoice reached via its
  public payment-link token — the `/pay/:token` page's own flow, with
  no card on file and no logged-in payer to scope against.
  """
  def pay_via_link(%Invoice{} = invoice, payment_method) when is_binary(payment_method) do
    with {:ok, %{id: intent_id}} <- submit_charge(invoice, payment_method, off_session: false) do
      finalize_charge_submission(invoice, invoice_client(invoice), intent_id, "payment_link")
    end
  end

  defp submit_charge(%Invoice{} = invoice, payment_method, opts) do
    StripeGateway.create_payment_intent(%{
      amount_cents: invoice.amount_cents,
      payment_method: payment_method,
      off_session: Keyword.get(opts, :off_session, false),
      metadata: %{invoice_id: invoice.id}
    })
  end

  # Clients doesn't yet persist a real Stripe payment-method/customer id
  # (only the `card_on_file` flag) — this placeholder stands in until a
  # SetupIntent-backed token is stored. The Test adapter ignores it
  # entirely, and the Live adapter is never exercised without one.
  defp payment_method_for(%Client{id: id}), do: "card_on_file:#{id}"

  defp finalize_charge_submission(%Invoice{} = invoice, client, intent_id, source) do
    Repo.transact(fn ->
      with {:ok, updated} <-
             invoice
             |> Invoice.changeset(%{status: :charge_pending, stripe_payment_intent_id: intent_id})
             |> Repo.update(),
           {:ok, _payment} <- record_payment(updated, intent_id, source, :pending) do
        {:ok, updated}
      end
    end)
    |> tap(fn
      {:ok, updated} -> send_receipt(client, updated)
      _error -> :ok
    end)
  end

  @doc """
  Generates (or reuses) an invoice's public payment-link token, so the
  owner can share `/pay/:token` with a client who has no card on file.
  """
  def create_payment_link(
        %Scope{active_account_id: account_id},
        %Invoice{account_id: account_id} = invoice
      )
      when not is_nil(account_id) do
    invoice
    |> Invoice.changeset(%{payment_token: invoice.payment_token || generate_token()})
    |> Repo.update()
  end

  defp generate_token, do: 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

  defp invoice_client(%Invoice{} = invoice) do
    invoice |> Repo.preload(job: :client) |> then(& &1.job.client)
  end

  defp send_receipt(%Client{email: email}, %Invoice{} = invoice) when is_binary(email) do
    ReceiptNotifier.deliver_receipt(email, invoice)
    :ok
  end

  defp send_receipt(_client, _invoice), do: :ok

  defp record_payment(%Invoice{} = invoice, intent_id, source, status) do
    %Payment{account_id: invoice.account_id, invoice_id: invoice.id}
    |> Payment.changeset(%{
      amount_cents: invoice.amount_cents,
      status: status,
      provider: "stripe",
      stripe_payment_intent_id: intent_id,
      source: source
    })
    |> Repo.insert()
  end

  ## Webhook

  @doc """
  Verifies and applies an inbound Stripe webhook request — the
  controller's only touchpoint into this context, so it never sees
  event data it can't trust.
  """
  def receive_webhook(conn) do
    with {:ok, event} <- StripeGateway.verify_webhook_event(conn) do
      apply_webhook_event(event)
    end
  end

  defp apply_webhook_event(%{"type" => "payment_intent.succeeded"} = event) do
    with {:ok, invoice} <- find_invoice_for_event(event) do
      transition_invoice(invoice, :paid, :succeeded)
    end
  end

  defp apply_webhook_event(%{"type" => "payment_intent.payment_failed"} = event) do
    with {:ok, invoice} <- find_invoice_for_event(event) do
      transition_invoice(invoice, :unpaid, :failed)
    end
  end

  defp apply_webhook_event(%{"type" => _other}), do: {:ok, :ignored}

  defp find_invoice_for_event(%{"data" => %{"object" => object}}) do
    case object do
      %{"metadata" => %{"invoice_id" => invoice_id}} when is_binary(invoice_id) ->
        fetch_invoice(invoice_id)

      %{"id" => intent_id} when is_binary(intent_id) ->
        fetch_invoice_by_intent(intent_id)

      _ ->
        {:error, :invoice_not_found}
    end
  end

  defp fetch_invoice(invoice_id) do
    case Repo.get(Invoice, invoice_id) do
      nil -> {:error, :invoice_not_found}
      invoice -> {:ok, invoice}
    end
  end

  defp fetch_invoice_by_intent(intent_id) do
    case Repo.get_by(Invoice, stripe_payment_intent_id: intent_id) do
      nil -> {:error, :invoice_not_found}
      invoice -> {:ok, invoice}
    end
  end

  # `stripe_payment_intent_id` is left as-is on a decline (never
  # cleared) — its presence is what tells `CleanerCrmWeb.InvoiceLive.Show`
  # to offer "retry" instead of the initial "charge card" action.
  defp transition_invoice(%Invoice{} = invoice, new_status, payment_status) do
    Repo.transact(fn ->
      with {:ok, updated} <- invoice |> Invoice.changeset(%{status: new_status}) |> Repo.update() do
        update_payment_record(updated, payment_status)
        {:ok, updated}
      end
    end)
  end

  # The `Payment` submitted alongside the charge is normally still
  # `:pending` here and just gets its outcome filled in; a fixture-seeded
  # invoice (no prior `charge_card/2` call) has none, so one is created
  # for the audit trail.
  defp update_payment_record(%Invoice{} = invoice, status) do
    case Repo.get_by(Payment,
           invoice_id: invoice.id,
           stripe_payment_intent_id: invoice.stripe_payment_intent_id
         ) do
      nil -> record_payment(invoice, invoice.stripe_payment_intent_id, "webhook", status)
      payment -> payment |> Payment.changeset(%{status: status}) |> Repo.update()
    end
  end
end
