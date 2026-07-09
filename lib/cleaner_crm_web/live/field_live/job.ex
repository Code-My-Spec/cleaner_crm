defmodule CleanerCrmWeb.FieldLive.Job do
  @moduledoc """
  A single job workspace: the room-by-room checklist, clock in/out
  with running earnings, and incident reporting.

  Route: `/field/jobs/:id`. A cleaner who opens a job not assigned to
  them is redirected straight back to `/field` with a flash — the
  page exposes entry codes and client details, so an unassigned
  cleaner must never see it render at all (reconciled with story
  838's criterion 7123 and story 844's criterion 7129). Office staff
  (an account's `:owner`/`:admin`) can open any job in the account,
  assigned or not — story 836's criterion 7153 exercises exactly that,
  completing a job that was never assigned to a specific cleaner.

  ## Dependencies

  - `CleanerCrm.Scheduling`
  - `CleanerCrm.Quality`
  - `CleanerCrm.TimeTracking`
  - `CleanerCrm.Accounts` — only to distinguish office staff from a
    field cleaner for the check above.
  - `CleanerCrmWeb.FieldLive.ChecklistComponent`
  - `CleanerCrmWeb.FieldLive.IncidentFormComponent`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Accounts
  alias CleanerCrm.Money
  alias CleanerCrm.Quality
  alias CleanerCrm.Scheduling
  alias CleanerCrm.TimeTracking
  alias CleanerCrm.TimeTracking.{Earnings, TimeEntry}
  alias CleanerCrmWeb.FieldLive.{ChecklistComponent, IncidentFormComponent}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-lg mx-auto px-2 pb-8">
        <.header>
          {client_name(@job)}
          <:subtitle>
            {@job.scheduled_date} · {format_time(@job.start_time)}–{format_time(@job.end_time)}
          </:subtitle>
          <:actions>
            <span :if={@job.status == :completed} class="badge badge-success">Complete</span>
          </:actions>
        </.header>

        <div class="card bg-base-100 border border-base-300 mb-4">
          <div class="card-body">
            <p :if={@clock_in_warning} data-test="clock-in-warning" class="text-error text-sm mb-2">
              You're still clocked in to your {@clock_in_warning.client &&
                @clock_in_warning.client.name} job — clock out there first.
            </p>

            <div :if={@open_entry} class="flex items-center justify-between gap-2">
              <span>Clocked in</span>
              <span data-test="elapsed-time">{format_duration(@elapsed_seconds)}</span>
              <.button data-test="clock-out-button" phx-click="clock_out">Clock Out</.button>
            </div>

            <p
              :if={@open_entry}
              data-test="missing-clock-out-notice"
              class="text-warning text-sm mt-1"
            >
              Missing clock-out — remember to clock out when you're done.
            </p>

            <div :if={!@open_entry} class="flex items-center justify-between gap-2">
              <span :if={@last_worked_seconds}>Clocked out</span>
              <span :if={@last_worked_seconds} data-test="worked-time">
                {format_duration(@last_worked_seconds)}
              </span>
              <.button data-test="clock-in-button" phx-click="clock_in">Clock In</.button>
            </div>

            <p :if={@earnings_cents} data-test="job-earnings" class="mt-2 font-semibold">
              {Money.format_cents(@earnings_cents)}
            </p>
          </div>
        </div>

        <.live_component
          module={ChecklistComponent}
          id="checklist"
          current_scope={@current_scope}
          job={@job}
          checklist={@checklist}
        />

        <.live_component
          module={IncidentFormComponent}
          id="incident-form"
          current_scope={@current_scope}
          job={@job}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope
    job = Scheduling.get_job!(scope, id)

    if assigned_to_viewer?(scope, job) or office_staff?(scope) do
      {:ok,
       socket
       |> assign(:job, job)
       |> assign(:page_title, "Job")
       |> assign(:clock_in_warning, nil)
       |> load_checklist()
       |> load_time_state()
       |> maybe_schedule_tick()}
    else
      {:ok,
       socket
       |> put_flash(:error, "This job is not assigned to you.")
       |> redirect(to: ~p"/field")}
    end
  end

  @impl true
  def handle_event("clock_in", _params, socket) do
    scope = socket.assigns.current_scope
    job = socket.assigns.job

    case TimeTracking.clock_in(scope, job) do
      {:ok, _entry} ->
        {:noreply, socket |> assign(:clock_in_warning, nil) |> load_time_state()}

      {:error, {:already_clocked_in, other_job}} ->
        {:noreply, assign(socket, :clock_in_warning, Scheduling.get_job!(scope, other_job.id))}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("clock_out", _params, socket) do
    scope = socket.assigns.current_scope
    job = socket.assigns.job

    case TimeTracking.clock_out(scope, job) do
      {:ok, _entry} -> {:noreply, load_time_state(socket)}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:job_completed, socket) do
    job = Scheduling.get_job!(socket.assigns.current_scope, socket.assigns.job.id)
    {:noreply, socket |> assign(:job, job) |> load_checklist()}
  end

  def handle_info(:checklist_changed, socket), do: {:noreply, load_checklist(socket)}

  # The tick must stay DB-free: it fires every second for as long as
  # the page is open (a query per second per viewer), and in test this
  # process can outlive the test that mounted it — a DB call here then
  # lands on a torn-down sandbox connection, and the resulting
  # Postgrex/GenServer error log fails whatever unrelated test is
  # running at that moment. Elapsed time is plain arithmetic off the
  # already-assigned open entry; events that change time state
  # (clock in/out) reload it via `load_time_state/1`.
  def handle_info(:tick, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, 1000)

    elapsed =
      case socket.assigns.open_entry do
        nil -> socket.assigns.elapsed_seconds
        entry -> DateTime.diff(DateTime.utc_now(), entry.clocked_in_at)
      end

    {:noreply, assign(socket, :elapsed_seconds, elapsed)}
  end

  # `Swoosh.Adapters.Test` (test env only) messages every PID in the
  # sending process's `$callers` chain, not just the test itself — so
  # a hook fired synchronously from this LiveView's own `handle_event`
  # (e.g. `CleanerCrm.Reviews.request_review/1`'s immediate thank-you)
  # lands its `{:email, _}` back here too. Ignored rather than
  # crashing the process — many tests keep interacting with this
  # LiveView after completion (checking rendered state, etc.), so it
  # must stay alive. Production never sends this message at all.
  def handle_info({:email, _email}, socket), do: {:noreply, socket}
  def handle_info({:emails, _emails}, socket), do: {:noreply, socket}

  defp maybe_schedule_tick(socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, 1000)
    socket
  end

  defp assigned_to_viewer?(scope, job), do: job.cleaner_id == scope.user.id

  defp office_staff?(scope) do
    case scope.active_account_id do
      nil -> false
      account_id -> Accounts.get_user_role(scope, scope.user.id, account_id) in [:owner, :admin]
    end
  end

  # Every job gets a checklist to complete through, even a trivially
  # empty one for a job nothing ever assigned a template to — lazily
  # instantiated here so `ChecklistComponent`'s completion flow (and
  # the invoice it triggers) is the one path every job completes
  # through, rather than a second one this view would otherwise need
  # for the no-checklist case.
  defp load_checklist(socket) do
    scope = socket.assigns.current_scope
    job = socket.assigns.job

    checklist =
      case Quality.get_checklist_for_job(scope, job) do
        nil ->
          {:ok, checklist} = Quality.create_checklist(scope, job, [])
          checklist

        checklist ->
          checklist
      end

    assign(socket, :checklist, checklist)
  end

  defp load_time_state(socket) do
    scope = socket.assigns.current_scope
    job = socket.assigns.job
    entries = TimeTracking.list_time_entries_for_job(scope, job)
    last_resolved = entries |> Enum.filter(&TimeEntry.resolved?/1) |> List.last()

    socket
    |> assign(:open_entry, TimeTracking.open_time_entry_for_job(scope, job))
    |> assign(:elapsed_seconds, TimeTracking.elapsed_seconds(scope, job))
    |> assign(:last_worked_seconds, last_resolved && Earnings.worked_seconds(last_resolved))
    |> assign(:earnings_cents, TimeTracking.job_earnings_cents(scope, job))
  end

  defp client_name(%{client: %{name: name}}) when is_binary(name), do: name
  defp client_name(%{property: %{client: %{name: name}}}) when is_binary(name), do: name
  defp client_name(_job), do: "Job"

  defp format_time(time), do: Calendar.strftime(time, "%-H:%M")

  defp format_duration(nil), do: "0m"

  defp format_duration(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    "#{hours}h #{minutes}m"
  end
end
