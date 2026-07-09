# Story 834 QA seed script — idempotent. Run with:
#   mix run priv/repo/qa_seeds_834.exs
#
# Builds on priv/repo/qa_seeds.exs (owner + cleaner + account must already
# exist). Adds cleaners and jobs covering all 5 acceptance criteria for
# "Dispatch from a single weekly schedule board":
#   - 4 cleaners each with a job Mon-Thu this week (whole-week-at-a-glance)
#   - Ben also has a Wed 10am-12pm job (conflict target)
#   - Ana has a Wed 1-3pm job (reassign-to-Ben target, no conflict)
#   - Ana has a Wed 11am-12pm job (conflict source — overlaps Ben's 10-12)
#   - An unassigned Thu 2-4pm job (dispatch target)
#
# Ben is a real password-login user (not a placeholder) so criterion 7177
# can be verified by actually logging in as Ben in the browser.

alias CleanerCrm.{Users, Accounts, Clients, Scheduling}
alias CleanerCrm.Users.Scope

qa_password = "qa password 1234"

owner = Users.get_user_by_email("qa-owner@cleanercrm.test") || raise "run qa_seeds.exs first"
owner_scope = Scope.for_user(owner)
[account | _] = Accounts.list_accounts(owner_scope)
scope = %{owner_scope | active_account: account, active_account_id: account.id}

ensure_login_user = fn email ->
  case Users.get_user_by_email(email) do
    nil ->
      {:ok, user} = Users.register_user(%{email: email})
      {:ok, email_struct} = Users.deliver_login_instructions(user, &"[TOKEN]#{&1}[TOKEN]")
      [_, token | _] = String.split(email_struct.text_body, "[TOKEN]")
      {:ok, {user, _}} = Users.login_user_by_magic_link(token)
      {:ok, {user, _}} = Users.update_user_password(user, %{password: qa_password})
      user

    user ->
      user
  end
end

ensure_member = fn user ->
  already_member? =
    scope
    |> Accounts.list_account_members(account.id)
    |> Enum.any?(&(&1.user_id == user.id))

  unless already_member? do
    {:ok, _member} = Accounts.add_user_to_account(scope, user.id, account.id, :member)
  end
end

ensure_cleaner = fn name ->
  case Scheduling.list_cleaners(scope) |> Enum.find(&(&1.name == name)) do
    nil ->
      {:ok, cleaner} = Scheduling.register_cleaner(scope, name)
      cleaner

    cleaner ->
      cleaner
  end
end

ensure_client = fn name ->
  case Clients.list_clients(scope) |> Enum.find(&(&1.name == name)) do
    nil ->
      {:ok, client} = Clients.create_client(scope, %{name: name})
      client

    client ->
      client
  end
end

ensure_job = fn attrs ->
  scheduled_date = Map.fetch!(attrs, :scheduled_date)
  start_time = Map.fetch!(attrs, :start_time)

  existing =
    scope
    |> Scheduling.list_jobs()
    |> Enum.find(&(&1.scheduled_date == scheduled_date and &1.start_time == start_time and
                     &1.client_id == attrs[:client_id]))

  case existing do
    nil ->
      {:ok, job} = Scheduling.create_job(scope, attrs)
      job

    job ->
      job
  end
end

today = Date.utc_today()
monday = Date.add(today, -(Date.day_of_week(today) - 1))
wednesday = Date.add(monday, 2)
thursday = Date.add(monday, 3)

ben = ensure_login_user.("qa-ben-834@cleanercrm.test")
ensure_member.(ben)

ana = ensure_cleaner.("Ana QA834")
chloe = ensure_cleaner.("Chloe QA834")
dana = ensure_cleaner.("Dana QA834")

client_a = ensure_client.("Story834 Client A")
client_b = ensure_client.("Story834 Client B")
client_c = ensure_client.("Story834 Client C")
client_d = ensure_client.("Story834 Client D")
client_e = ensure_client.("Story834 Client E")
client_unassigned = ensure_client.("Story834 Client Unassigned")

# Whole-week-at-a-glance: one job per cleaner, Mon-Thu
mon_job =
  ensure_job.(%{
    client_id: client_a.id,
    cleaner_id: ana.id,
    scheduled_date: monday,
    start_time: ~T[09:00:00],
    end_time: ~T[11:00:00],
    agreed_price: Decimal.new("100.00")
  })

tue_job =
  ensure_job.(%{
    client_id: client_b.id,
    cleaner_id: ben.id,
    scheduled_date: Date.add(monday, 1),
    start_time: ~T[09:00:00],
    end_time: ~T[11:00:00],
    agreed_price: Decimal.new("100.00")
  })

wed_job_chloe =
  ensure_job.(%{
    client_id: client_c.id,
    cleaner_id: chloe.id,
    scheduled_date: wednesday,
    start_time: ~T[09:00:00],
    end_time: ~T[11:00:00],
    agreed_price: Decimal.new("100.00")
  })

thu_job_dana =
  ensure_job.(%{
    client_id: client_d.id,
    cleaner_id: dana.id,
    scheduled_date: thursday,
    start_time: ~T[09:00:00],
    end_time: ~T[11:00:00],
    agreed_price: Decimal.new("100.00")
  })

# Reassign target: Ana's Wed 1-3pm job -> will be moved to Ben in-browser
reassign_job =
  ensure_job.(%{
    client_id: client_e.id,
    cleaner_id: ana.id,
    scheduled_date: wednesday,
    start_time: ~T[13:00:00],
    end_time: ~T[15:00:00],
    agreed_price: Decimal.new("120.00")
  })

# Conflict setup: Ben already has Wed 10am-12pm
ben_conflict_job =
  ensure_job.(%{
    client_id: client_b.id,
    cleaner_id: ben.id,
    scheduled_date: wednesday,
    start_time: ~T[10:00:00],
    end_time: ~T[12:00:00],
    agreed_price: Decimal.new("100.00")
  })

# Conflict source: Ana's Wed 11am-12pm job -> attempting to move onto Ben must be rejected
conflict_source_job =
  ensure_job.(%{
    client_id: client_a.id,
    cleaner_id: ana.id,
    scheduled_date: wednesday,
    start_time: ~T[11:00:00],
    end_time: ~T[12:00:00],
    agreed_price: Decimal.new("80.00")
  })

# Dispatch target: unassigned Thu 2-4pm job
unassigned_job =
  ensure_job.(%{
    client_id: client_unassigned.id,
    cleaner_id: nil,
    scheduled_date: thursday,
    start_time: ~T[14:00:00],
    end_time: ~T[16:00:00],
    agreed_price: Decimal.new("90.00")
  })

IO.puts("""

Story 834 QA seed complete.

  Cleaners:
    Ana QA834:   id=#{ana.id}
    Ben:         id=#{ben.id}  login=qa-ben-834@cleanercrm.test / #{qa_password}
    Chloe QA834: id=#{chloe.id}
    Dana QA834:  id=#{dana.id}

  Jobs:
    Monday    (whole-week):        job-#{mon_job.id}    Ana
    Tuesday   (whole-week):        job-#{tue_job.id}    Ben
    Wednesday (whole-week):        job-#{wed_job_chloe.id}    Chloe
    Thursday  (whole-week):        job-#{thu_job_dana.id}    Dana
    Wednesday (reassign target):   job-#{reassign_job.id}    Ana 1-3pm -> move to Ben
    Wednesday (Ben's existing):    job-#{ben_conflict_job.id}    Ben 10am-12pm
    Wednesday (conflict source):   job-#{conflict_source_job.id}    Ana 11am-12pm -> moving to Ben must be BLOCKED
    Thursday  (unassigned):        job-#{unassigned_job.id}    unassigned 2-4pm -> assign to Chloe or Dana

  Week Monday: #{monday}
""")
