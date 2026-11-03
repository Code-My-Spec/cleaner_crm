defmodule Mix.Tasks.Crm.ImportMaidilyTest do
  use CleanerCrmTest.DataCase, async: false

  alias CleanerCrm.{Clients, Imports, Scheduling}
  alias Mix.Tasks.Crm.ImportMaidily

  @opts [account: "Test Cleaning Co", owner_email: "owner@example.test"]

  def write_fixtures! do
    dir = Path.join(System.tmp_dir!(), "maidily_import_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    files = %{
      "clients" => [
        %{
          "source_id" => 1,
          "name" => "Alice Example",
          "email" => "a@example.test",
          "phone" => "555-0100",
          "active" => true
        },
        %{
          "source_id" => 2,
          "name" => "Bob Example",
          "email" => nil,
          "phone" => nil,
          "active" => false
        }
      ],
      "properties" => [
        %{
          "source_id" => 1,
          "client_source_id" => 1,
          "service_address" => "1 Test St, Tucson, AZ 85701",
          "entry_method" => "key"
        },
        %{
          "source_id" => 2,
          "client_source_id" => 2,
          "service_address" => "2 Test St",
          "entry_method" => nil
        },
        %{
          "source_id" => 9,
          "client_source_id" => 9,
          "service_address" => "orphan",
          "entry_method" => nil
        }
      ],
      "cleaners" => [
        %{
          "source_id" => 7,
          "name" => "Casey Cleaner",
          "email" => "c@example.test",
          "phone" => nil,
          "active" => true
        }
      ],
      "jobs" => [
        job(100, "INV-1", 1, 7, "2026-05-20", "completed", 15000),
        job(101, "INV-2", 2, nil, "2026-05-21", "cancelled", 9000),
        job(102, "INV-3", 1, 7, "2026-05-22", "in_progress", 12000),
        job(103, "INV-4", 2, nil, "2027-01-10", "scheduled", 8000),
        job(104, "INV-5", 9, nil, "2026-05-23", "completed", 100)
      ],
      "quotes" => [
        %{
          "source_id" => 50,
          "source_ref" => "Q-1",
          "client_source_id" => 1,
          "client_name" => "Alice Example",
          "client_phone" => "555-0100",
          "pricing_model" => "per_room",
          "bedroom_count" => 3,
          "bathroom_count" => 2,
          "total_cents" => 20000,
          "status" => "sent"
        }
      ]
    }

    for {name, rows} <- files,
        do: File.write!(Path.join(dir, name <> ".json"), Jason.encode!(rows))

    dir
  end

  defp job(id, ref, client, cleaner, date, status, cents) do
    %{
      "source_id" => id,
      "source_ref" => ref,
      "client_source_id" => client,
      "cleaner_source_id" => cleaner,
      "scheduled_date" => date,
      "start_time" => "09:00:00",
      "end_time" => "11:00:00",
      "status" => status,
      "agreed_price_cents" => cents,
      "recurrence" => "weekly"
    }
  end

  test "imports every kind, assigns job numbers and statuses, writes import records" do
    result = ImportMaidily.run_import(write_fixtures!(), @opts)
    scope = result.scope

    assert result.counts["clients"] == %{ok: 2, failed: 0}
    assert result.counts["properties"] == %{ok: 2, failed: 1}
    assert result.counts["cleaners"] == %{ok: 1, failed: 0}
    assert result.counts["jobs"] == %{ok: 4, failed: 1}
    assert result.counts["quotes"] == %{ok: 1, failed: 0}
    assert [{"properties", "9", _}, {"jobs", "104", _}] = result.failures

    assert length(Clients.list_clients(scope)) == 2

    job_records = Imports.list_records(scope, kind: "job", limit: 50)
    assert length(job_records) == 4

    jobs = Enum.map(job_records, &Scheduling.get_job!(scope, &1.target_id))
    assert jobs |> Enum.map(& &1.job_number) |> Enum.sort() == [1001, 1002, 1003, 1004]

    assert jobs |> Enum.map(& &1.status) |> Enum.sort() == [
             :cancelled,
             :completed,
             :in_progress,
             :scheduled
           ]

    rec = Enum.find(job_records, &(&1.source_id == "100"))
    assert rec.source == "maidily"
    assert rec.source_ref == "INV-1"
    assert rec.raw["agreed_price_cents"] == 15000
    assert Scheduling.get_job!(scope, rec.target_id).agreed_price_cents == 15000
    assert Scheduling.get_job!(scope, rec.target_id).cleaner_id
    assert length(Imports.list_records(scope, kind: "client")) == 2
  end

  test "--limit and --only restrict what is imported" do
    result =
      ImportMaidily.run_import(
        write_fixtures!(),
        @opts ++ [limit: 1, only: ["clients", "cleaners"]]
      )

    assert result.counts == %{"clients" => %{ok: 1, failed: 0}, "cleaners" => %{ok: 1, failed: 0}}
    assert Scheduling.list_jobs(result.scope) == []
  end
end
