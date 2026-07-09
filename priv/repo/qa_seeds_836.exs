# Story 836 QA seed script — run with: mix run priv/repo/qa_seeds_836.exs
#
# Assumes priv/repo/qa_seeds.exs has already run (owner user + account
# exist). Creates:
#   - two clients + properties for driving job-completion -> invoice
#     flows through the UI (one with a card on file, one without)
#   - two invoices seeded directly in :charge_pending with a known
#     stripe_payment_intent_id, so the decline/success webhook paths
#     (criteria 7157/7158) can be exercised via curl without depending
#     on whether a real charge submission to Stripe succeeds first —
#     mirrors CleanerCrmSpex.Fixtures' own sanctioned shortcut for
#     these two criteria.
#
# Not idempotent (creates fresh entities each run) — safe to re-run,
# just accumulates a few more QA rows each time.

alias CleanerCrm.{Accounts, Billing, Clients, Quality, Scheduling, Users}
alias CleanerCrm.Users.Scope

owner = Users.get_user_by_email("qa-owner@cleanercrm.test") || raise "run qa_seeds.exs first"
owner_scope = Scope.for_user(owner)

[account | _] = Accounts.list_accounts(owner_scope)
scope = %{owner_scope | active_account_id: account.id, active_account: account}

{:ok, client_card} =
  Clients.create_client(scope, %{
    name: "QA Card Client 836",
    card_on_file: true,
    email: "qa-card-836@example.com",
    phone: "+15555550836"
  })

{:ok, property_card} =
  Clients.create_property(scope, %{client_id: client_card.id, service_address: "836 Card St"})

{:ok, client_nocard} =
  Clients.create_client(scope, %{
    name: "QA NoCard Client 836",
    card_on_file: false,
    email: "qa-nocard-836@example.com",
    phone: "+15555550837"
  })

{:ok, property_nocard} =
  Clients.create_property(scope, %{client_id: client_nocard.id, service_address: "837 NoCard Ave"})

# --- Pre-seeded charge_pending invoices for the webhook-decision specs ---

seed_pending_invoice = fn suffix, intent_id ->
  {:ok, job} =
    Scheduling.create_job(scope, %{
      client_id: client_card.id,
      property_id: property_card.id,
      agreed_price: Decimal.new("150.00"),
      status: :completed,
      scheduled_date: Date.utc_today(),
      start_time: ~T[09:00:00],
      end_time: ~T[11:00:00]
    })

  {:ok, _checklist} =
    Quality.complete_checklist(scope, job, [
      %{
        task: "Kitchen counters wiped down (#{suffix})",
        before_photo: "before_kitchen_#{suffix}.jpg",
        after_photo: "after_kitchen_#{suffix}.jpg"
      },
      %{
        task: "Bathrooms sanitized (#{suffix})",
        before_photo: "before_bath_#{suffix}.jpg",
        after_photo: "after_bath_#{suffix}.jpg"
      }
    ])

  {:ok, invoice} =
    Billing.create_invoice(scope, %{
      job_id: job.id,
      amount: job.agreed_price,
      status: :charge_pending,
      stripe_payment_intent_id: intent_id
    })

  invoice
end

invoice_for_decline = seed_pending_invoice.("decline", "pi_qa_836_declined")
invoice_for_success = seed_pending_invoice.("succeed", "pi_qa_836_succeeded")

IO.puts("""

Story 836 QA seed complete.

  Client with card on file:    #{client_card.name} (id: #{client_card.id}) / property #{property_card.id}
  Client with no card on file: #{client_nocard.name} (id: #{client_nocard.id}) / property #{property_nocard.id}

  Invoice seeded for DECLINE webhook test: #{invoice_for_decline.id} (intent #{invoice_for_decline.stripe_payment_intent_id})
  Invoice seeded for SUCCESS webhook test: #{invoice_for_success.id} (intent #{invoice_for_success.stripe_payment_intent_id})
""")
