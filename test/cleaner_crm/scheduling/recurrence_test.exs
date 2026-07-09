defmodule CleanerCrm.Scheduling.RecurrenceTest do
  use CleanerCrmTest.DataCase, async: true

  alias CleanerCrm.Scheduling.{Recurrence, RecurringPlan}

  describe "job_attrs/1" do
    test "carries the plan's agreed_price_cents onto every occurrence" do
      plan = %RecurringPlan{
        id: Ecto.UUID.generate(),
        property_id: Ecto.UUID.generate(),
        cleaner_id: nil,
        recurrence: :weekly,
        start_date: ~D[2026-08-03],
        occurrence_count: 3,
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        agreed_price_cents: 15_000
      }

      attrs = Recurrence.job_attrs(plan)

      assert length(attrs) == 3
      assert Enum.all?(attrs, &(&1.agreed_price_cents == 15_000))
    end

    # Reachable in real usage: a plan created with no price generates
    # visits with no price either, and completing one of those jobs must
    # not crash invoice generation (see `CleanerCrm.BillingTest`).
    test "carries a nil price through when the plan has none" do
      plan = %RecurringPlan{
        id: Ecto.UUID.generate(),
        property_id: Ecto.UUID.generate(),
        cleaner_id: nil,
        recurrence: :weekly,
        start_date: ~D[2026-08-03],
        occurrence_count: 2,
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        agreed_price_cents: nil
      }

      attrs = Recurrence.job_attrs(plan)

      assert length(attrs) == 2
      assert Enum.all?(attrs, &(&1.agreed_price_cents == nil))
    end
  end
end
