defmodule CleanerCrmMcp.Tools.SchedulingTest do
  use CleanerCrmTest.DataCase, async: true

  import CleanerCrm.ClientsFixtures
  import CleanerCrm.SchedulingFixtures, except: [cleaner_fixture: 3]
  import CleanerCrm.UsersFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.SchedulingFixtures
  alias CleanerCrm.Users.Scope
  alias CleanerCrmMcp.Catalog
  alias CleanerCrmMcp.Tools.Scheduling, as: S

  defp scope_fixture do
    scope = Scope.for_user(user_fixture())

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp setup_account(_) do
    scope = scope_fixture()
    client = client_fixture(scope, %{name: "Ann Client", phone: "555-0100"})
    property = property_fixture(scope, client, %{service_address: "1 Cactus Way"})

    cleaner =
      SchedulingFixtures.cleaner_fixture(scope, %{id: scope.active_account_id}, %{name: "Maria"})

    %{scope: scope, client: client, property: property, cleaner: cleaner}
  end

  defp run(tool, raw, scope) do
    {:ok, args} = Catalog.coerce(tool, raw)
    tool.call(args, scope)
  end

  test "group lists unique, well-formed tools" do
    tools = S.tools()
    assert length(tools) == length(Enum.uniq_by(tools, & &1.name()))

    for t <- tools do
      assert t.description() =~ ~r/\S/
      assert is_boolean(t.mutates?())
    end

    assert Enum.all?(tools, &(&1 in Catalog.tools()))
  end

  describe "jobs" do
    setup :setup_account

    test "create_job, get_job, list_jobs present a consistent shape", %{
      scope: scope,
      property: p,
      cleaner: c
    } do
      assert {:ok, job} =
               run(
                 S.CreateJob,
                 %{
                   "property_id" => p.id,
                   "date" => "2026-12-01",
                   "start_time" => "09:00",
                   "end_time" => "11:00",
                   "price" => 180.5,
                   "cleaner_id" => c.id
                 },
                 scope
               )

      assert job["job_number"] == 1001
      assert job["price_cents"] == 18050
      assert job["price"] == 180.5
      assert job["status"] == "scheduled"
      assert job["date"] == "2026-12-01"
      assert job["start_time"] == "09:00:00"
      assert job["client"]["name"] == "Ann Client"
      assert job["client"]["phone"] == "555-0100"
      assert job["property"]["address"] == "1 Cactus Way"
      assert job["cleaner"] == %{"id" => c.id, "name" => "Maria"}

      assert {:ok, ^job} = run(S.GetJob, %{"job_number" => "#1001"}, scope)
      assert {:ok, ^job} = run(S.GetJob, %{"id" => job["id"]}, scope)

      assert {:ok, [^job]} =
               run(
                 S.ListJobs,
                 %{"from" => "2026-12-01", "to" => "2026-12-01", "cleaner_id" => c.id},
                 scope
               )

      assert {:ok, []} = run(S.ListJobs, %{"from" => "2026-12-02"}, scope)
      assert {:error, _} = run(S.GetJob, %{}, scope)
      assert {:error, "no job with job_number 5"} = run(S.GetJob, %{"job_number" => 5}, scope)
    end

    test "create_job reports a cleaner conflict but still creates the job", %{
      scope: scope,
      property: p,
      cleaner: c
    } do
      availability_block_fixture(scope, c, %{date: ~D[2026-12-01]})

      raw = %{
        "property_id" => p.id,
        "date" => "2026-12-01",
        "start_time" => "09:00",
        "end_time" => "11:00",
        "cleaner_id" => c.id
      }

      assert {:ok, job} = run(S.CreateJob, raw, scope)
      assert job["cleaner"] == nil
      assert job["assignment_error"] =~ "time off"
    end

    test "create_job validates", %{scope: scope, property: p} do
      assert {:error, %Ecto.Changeset{}} =
               run(
                 S.CreateJob,
                 %{
                   "property_id" => p.id,
                   "date" => "2026-12-01",
                   "start_time" => "11:00",
                   "end_time" => "09:00"
                 },
                 scope
               )

      assert {:error, _} =
               run(
                 S.CreateJob,
                 %{
                   "property_id" => Ecto.UUID.generate(),
                   "date" => "2026-12-01",
                   "start_time" => "09:00",
                   "end_time" => "10:00"
                 },
                 scope
               )

      assert {:error, msg} = Catalog.coerce(S.CreateJob, %{"property_id" => p.id})
      assert msg =~ "`date` is required"
    end

    test "update_job reschedules and reprices", %{scope: scope, property: p} do
      job = job_fixture(scope, p)

      assert {:ok, updated} =
               run(
                 S.UpdateJob,
                 %{
                   "job_number" => job.job_number,
                   "date" => "2026-12-05",
                   "end_time" => "12:00",
                   "price" => 99
                 },
                 scope
               )

      assert updated["date"] == "2026-12-05"
      assert updated["end_time"] == "12:00:00"
      assert updated["price_cents"] == 9900

      assert {:error, "nothing to change" <> _} =
               run(S.UpdateJob, %{"job_number" => job.job_number}, scope)
    end

    test "assign, unassign, cancel", %{scope: scope, property: p, cleaner: c} do
      job = job_fixture(scope, p)

      assert {:ok, %{"cleaner" => %{"id" => id}}} =
               run(
                 S.AssignCleaner,
                 %{"job_number" => job.job_number, "cleaner_id" => c.id},
                 scope
               )

      assert id == c.id

      assert {:ok, %{"cleaner" => nil}} =
               run(S.UnassignCleaner, %{"job_number" => job.job_number}, scope)

      assert {:error, _} =
               run(S.AssignCleaner, %{"job_number" => job.job_number, "cleaner_id" => 0}, scope)

      assert {:ok, %{"status" => "cancelled"}} =
               run(S.CancelJob, %{"job_number" => job.job_number}, scope)

      assert {:error, "job " <> _} = run(S.CancelJob, %{"job_number" => job.job_number}, scope)
      assert {:ok, []} = run(S.ListJobs, %{}, scope)
      assert {:ok, [_]} = run(S.ListJobs, %{"status" => "cancelled"}, scope)
      assert {:error, _} = run(S.ListJobs, %{"status" => "bogus"}, scope)
    end

    test "assign_cleaner surfaces overlap", %{scope: scope, property: p, cleaner: c} do
      a = job_fixture(scope, p, %{cleaner_id: c.id})
      b = job_fixture(scope, p, %{start_time: ~T[10:00:00], end_time: ~T[12:00:00]})
      assert a.cleaner_id == c.id

      assert {:error, "the cleaner already has another job" <> _} =
               run(S.AssignCleaner, %{"job_number" => b.job_number, "cleaner_id" => c.id}, scope)
    end

    test "list_unassigned_jobs and check_slot", %{scope: scope, property: p, cleaner: c} do
      assigned =
        job_fixture(scope, p, %{cleaner_id: c.id, scheduled_date: Date.add(Date.utc_today(), 3)})

      open = job_fixture(scope, p)
      assert {:ok, [%{"job_number" => n}]} = run(S.ListUnassignedJobs, %{}, scope)
      assert n == open.job_number
      refute n == assigned.job_number

      day = Date.to_iso8601(open.scheduled_date)

      assert {:ok, %{"available" => false, "conflicting_jobs" => [%{"job_number" => ^n}]}} =
               run(
                 S.CheckSlot,
                 %{"date" => day, "start_time" => "10:00", "end_time" => "12:00"},
                 scope
               )

      assert {:ok, %{"available" => true, "conflicting_jobs" => []}} =
               run(
                 S.CheckSlot,
                 %{"date" => day, "start_time" => "11:00", "end_time" => "12:00"},
                 scope
               )

      assert {:error, _} =
               run(
                 S.CheckSlot,
                 %{"date" => day, "start_time" => "12:00", "end_time" => "11:00"},
                 scope
               )
    end

    test "another account's data is not visible", %{property: p} do
      other = scope_fixture()
      mine = scope_fixture()
      client = client_fixture(mine)
      prop = property_fixture(mine, client)
      job = job_fixture(mine, prop)
      assert p.id != prop.id

      assert {:error, _} = run(S.GetJob, %{"job_number" => job.job_number}, other)
      assert {:error, _} = run(S.GetJob, %{"id" => job.id}, other)
      assert {:error, _} = run(S.CancelJob, %{"id" => job.id}, other)
      assert {:ok, []} = run(S.ListJobs, %{}, other)

      assert {:error, _} =
               run(
                 S.CreateJob,
                 %{
                   "property_id" => prop.id,
                   "date" => "2026-12-01",
                   "start_time" => "09:00",
                   "end_time" => "10:00"
                 },
                 other
               )

      assert {:ok, [_]} = run(S.ListJobs, %{"client_id" => client.id}, mine)
    end
  end

  describe "cleaners and availability" do
    setup :setup_account

    test "list, get, register", %{scope: scope, cleaner: c, property: p} do
      assert {:ok, list} = run(S.ListCleaners, %{}, scope)
      assert %{"id" => c.id, "name" => "Maria"} in list

      assert {:ok, %{"name" => "Zed", "id" => zid}} =
               run(S.RegisterCleaner, %{"name" => " Zed "}, scope)

      assert {:error, _} = run(S.RegisterCleaner, %{"name" => "  "}, scope)
      assert {:ok, list} = run(S.ListCleaners, %{}, scope)
      assert Enum.any?(list, &(&1["id"] == zid))

      job_fixture(scope, p, %{cleaner_id: c.id})

      assert {:ok, %{"name" => "Maria", "upcoming_jobs" => [_], "time_off" => []}} =
               run(S.GetCleaner, %{"cleaner_id" => c.id}, scope)

      assert {:error, _} = run(S.GetCleaner, %{"cleaner_id" => 0}, scope)
    end

    test "cleaner of another account is not found", %{cleaner: c} do
      assert {:error, _} = run(S.GetCleaner, %{"cleaner_id" => c.id}, scope_fixture())
    end

    test "availability blocks and cleaner_schedule", %{scope: scope, cleaner: c, property: p} do
      assert {:ok, %{"all_day" => true, "date" => "2026-12-03"}} =
               run(
                 S.CreateAvailabilityBlock,
                 %{"cleaner_id" => c.id, "date" => "2026-12-03", "all_day" => true},
                 scope
               )

      assert {:error, %Ecto.Changeset{}} =
               run(
                 S.CreateAvailabilityBlock,
                 %{"cleaner_id" => c.id, "date" => "2026-12-04"},
                 scope
               )

      assert {:ok, [%{"date" => "2026-12-03"}]} =
               run(
                 S.ListAvailabilityBlocks,
                 %{"cleaner_id" => c.id, "from" => "2026-12-01"},
                 scope
               )

      assert {:ok, []} =
               run(
                 S.ListAvailabilityBlocks,
                 %{"cleaner_id" => c.id, "from" => "2026-12-10"},
                 scope
               )

      job_fixture(scope, p, %{cleaner_id: c.id, scheduled_date: ~D[2026-12-02]})

      assert {:ok, %{"cleaner" => %{"name" => "Maria"}, "jobs" => [_], "time_off" => [_]}} =
               run(
                 S.CleanerSchedule,
                 %{"cleaner_id" => c.id, "from" => "2026-12-01", "to" => "2026-12-07"},
                 scope
               )
    end
  end

  describe "recurring plans" do
    setup :setup_account

    test "create, list, get, preview", %{scope: scope, property: p, cleaner: c} do
      availability_block_fixture(scope, c, %{date: ~D[2026-12-15]})

      raw = %{
        "property_id" => p.id,
        "recurrence" => "every_3_weeks",
        "start_date" => "2026-12-01",
        "occurrence_count" => 3,
        "price" => 120,
        "cleaner_id" => c.id
      }

      assert {:ok, %{"dates" => ["2026-12-01", "2026-12-22", "2027-01-12"], "conflicts" => []}} =
               run(S.PreviewPlanConflicts, raw, scope)

      raw_conflict = Map.put(raw, "start_date", "2026-12-01") |> Map.put("recurrence", "biweekly")

      assert {:ok,
              %{"conflicts" => [%{"index" => 2, "date" => "2026-12-15", "reason" => reason}]}} =
               run(S.PreviewPlanConflicts, raw_conflict, scope)

      assert reason =~ "time off"

      assert {:ok, plan} = run(S.CreateRecurringPlan, raw, scope)
      assert plan["recurrence"] == "every_3_weeks"
      assert plan["price_cents"] == 12000
      assert [%{"job_number" => 1001, "date" => "2026-12-01"}, _, _] = plan["jobs"]

      assert Enum.all?(
               plan["jobs"],
               &(&1["recurring_plan_id"] == plan["id"] and &1["cleaner"]["id"] == c.id)
             )

      assert plan["conflicts"] == []

      assert {:ok, [listed]} = run(S.ListRecurringPlans, %{}, scope)
      assert listed["id"] == plan["id"]

      assert {:ok, ^plan} =
               run(S.GetRecurringPlan, %{"id" => plan["id"]}, scope)
               |> then(fn {:ok, g} ->
                 {:ok, Map.delete(g, "conflicts") |> Map.put("conflicts", [])}
               end)

      assert {:error, _} = run(S.GetRecurringPlan, %{"id" => plan["id"]}, scope_fixture())
      assert {:ok, []} = run(S.ListRecurringPlans, %{}, scope_fixture())

      assert {:error, %Ecto.Changeset{}} =
               run(S.CreateRecurringPlan, Map.put(raw, "occurrence_count", 0), scope)
    end
  end
end
