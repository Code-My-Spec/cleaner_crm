defmodule CleanerCrm.TimeTracking.EarningsTest do
  use ExUnit.Case, async: true

  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.TimeTracking.Earnings
  alias CleanerCrm.TimeTracking.TimeEntry

  describe "job_cents/2" do
    test "piece-rate pays the flat amount regardless of entries" do
      job = %Job{pay_type: :piece_rate, piece_rate_cents: 8000}

      assert Earnings.job_cents(job, []) == 8000
      assert Earnings.job_cents(job, [resolved_entry(hours: 5)]) == 8000
    end

    test "hourly pays the rate times worked hours" do
      job = %Job{pay_type: :hourly, hourly_rate_cents: 2500}

      assert Earnings.job_cents(job, [resolved_entry(hours: 2.5)]) == 6250
    end

    test "hourly sums worked time across multiple resolved entries" do
      job = %Job{pay_type: :hourly, hourly_rate_cents: 2000}

      entries = [resolved_entry(hours: 1), resolved_entry(hours: 2)]
      assert Earnings.job_cents(job, entries) == 6000
    end

    test "hourly is nil with no entries yet" do
      job = %Job{pay_type: :hourly, hourly_rate_cents: 2500}
      assert Earnings.job_cents(job, []) == nil
    end

    test "hourly is nil while any entry is still open" do
      job = %Job{pay_type: :hourly, hourly_rate_cents: 2500}
      entries = [resolved_entry(hours: 1), open_entry()]

      assert Earnings.job_cents(job, entries) == nil
    end

    test "nil pay type never defaults to a price" do
      assert Earnings.job_cents(%Job{}, [resolved_entry(hours: 3)]) == nil
    end
  end

  describe "worked_seconds/1 and elapsed_seconds/1" do
    test "worked_seconds is the resolved clock-in to clock-out span" do
      entry = resolved_entry(hours: 2)
      assert Earnings.worked_seconds(entry) == 7200
    end

    test "elapsed_seconds counts from clock-in to now for an open entry" do
      entry = %TimeEntry{clocked_in_at: DateTime.add(DateTime.utc_now(), -600, :second)}
      assert_in_delta Earnings.elapsed_seconds(entry), 600, 2
    end
  end

  defp resolved_entry(hours: hours) do
    clocked_in_at = ~U[2024-01-08 09:00:00Z]
    clocked_out_at = DateTime.add(clocked_in_at, round(hours * 3600), :second)
    %TimeEntry{clocked_in_at: clocked_in_at, clocked_out_at: clocked_out_at}
  end

  defp open_entry, do: %TimeEntry{clocked_in_at: ~U[2024-01-08 09:00:00Z], clocked_out_at: nil}
end
