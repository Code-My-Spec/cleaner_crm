defmodule CleanerCrmWeb.FieldLive.Today do
  @moduledoc """
  The cleaner's day view: today's (or a looked-ahead day's) jobs in
  start-time order, each carrying everything needed to get in the
  door, plus any pending schedule-change alerts and the current
  pay-period earnings summary.

  Route: `/field`, with an optional `?date=` query param to look
  ahead at a future day. Lockbox/alarm codes unmask only once the
  real calendar date reaches a job's own scheduled date — never
  earlier, regardless of which day is currently being browsed.

  ## Dependencies

  - `CleanerCrm.Scheduling` — the account's jobs, filtered here to
    this cleaner's own jobs for the selected day.
  - `CleanerCrm.Notifications` — read defensively (`Code.ensure_loaded?/1`
    + `function_exported?/3`): it may land after this view does, and
    this view must never crash for its absence.
  - `CleanerCrmWeb.FieldLive.EarningsComponent`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Scheduling
  alias CleanerCrmWeb.FieldLive.EarningsComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div data-test="field-today" class="max-w-lg mx-auto px-2 pb-8">
        <.header>
          {Calendar.strftime(@date, "%A, %B %-d")}
          <:subtitle>{length(@jobs)} job{if length(@jobs) == 1, do: "", else: "s"} today</:subtitle>
        </.header>

        <div
          :for={notification <- @notifications}
          data-test={"schedule-alert-#{notification.id}"}
          class="alert alert-warning mb-3"
        >
          <div>
            <p data-test="schedule-alert" class="font-semibold">Schedule change</p>
            <p>{notification.change_summary}</p>
          </div>
          <button
            type="button"
            data-test={"schedule-alert-#{notification.id}-acknowledge-button"}
            phx-click="acknowledge_notification"
            phx-value-token={notification.token}
            class="btn btn-sm"
          >
            Acknowledge
          </button>
        </div>

        <.live_component
          module={EarningsComponent}
          id="pay-period-earnings"
          current_scope={@current_scope}
        />

        <div
          :if={@jobs == []}
          data-test="empty-day-state"
          class="card bg-base-100 border border-base-300"
        >
          <div class="card-body items-center text-center">
            <p>No jobs scheduled for this day.</p>
          </div>
        </div>

        <div
          :for={job <- @jobs}
          data-test="job-card"
          class="card bg-base-100 border border-base-300 mt-3"
        >
          <div class="card-body">
            <div class="flex justify-between items-baseline">
              <span class="font-semibold" data-test="job-start-time">{format_time(job.start_time)}</span>
              <.link navigate={~p"/field/jobs/#{job.id}"} class="link link-primary text-sm">
                Open job
              </.link>
            </div>

            <div data-test="job-address" class="text-sm">{address(job)}</div>

            <dl class="text-sm mt-2 space-y-1">
              <div>
                <dt class="inline font-medium">Entry:</dt>
                <dd data-test="job-entry-method" class="inline">
                  {detail(job, :entry_method, "No entry method on file")}
                </dd>
              </div>
              <div>
                <dt class="inline font-medium">Parking:</dt>
                <dd data-test="job-parking-notes" class="inline">
                  {detail(job, :parking_notes, "No parking notes")}
                </dd>
              </div>
              <div>
                <dt class="inline font-medium">Pets:</dt>
                <dd data-test="job-pet-notes" class="inline">
                  {detail(job, :pet_notes, "No pet notes on file")}
                </dd>
              </div>
              <div>
                <dt class="inline font-medium">Preferences:</dt>
                <dd data-test="job-client-preferences" class="inline">
                  {detail(job, :client_preferences, "No client preferences on file")}
                </dd>
              </div>
            </dl>

            <.access_codes job={job} />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :job, :map, required: true

  defp access_codes(assigns) do
    ~H"""
    <div
      :if={@job.property && (@job.property.lockbox_code || @job.property.alarm_code)}
      class="mt-2 text-sm"
    >
      <div :if={@job.property.lockbox_code}>
        <span class="font-medium">Lockbox:</span>
        <span data-test="job-lockbox-code" data-masked={to_string(!unlocked?(@job))}>
          {mask_or_reveal(@job, @job.property.lockbox_code)}
        </span>
      </div>
      <div :if={@job.property.alarm_code}>
        <span class="font-medium">Alarm:</span>
        <span data-test="job-alarm-code" data-masked={to_string(!unlocked?(@job))}>
          {mask_or_reveal(@job, @job.property.alarm_code)}
        </span>
      </div>
      <p :if={!unlocked?(@job)} data-test="lockbox-unlock-notice" class="text-xs opacity-70">
        Unlocks on the day of the job
      </p>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    date = parse_date(params["date"]) || Date.utc_today()

    {:ok,
     socket
     |> assign(:date, date)
     |> assign(:page_title, "Today")
     |> load_jobs()
     |> load_notifications()}
  end

  @impl true
  def handle_event("acknowledge_notification", %{"token" => token}, socket) do
    CleanerCrm.Notifications.acknowledge(token)
    {:noreply, load_notifications(socket)}
  end

  defp load_jobs(socket) do
    scope = socket.assigns.current_scope
    date = socket.assigns.date

    jobs =
      scope
      |> Scheduling.list_jobs_for_week(week_start(date))
      |> Enum.filter(&(&1.scheduled_date == date and &1.cleaner_id == scope.user.id))
      |> Enum.sort_by(& &1.start_time, Time)

    assign(socket, :jobs, jobs)
  end

  # `CleanerCrm.Notifications` (story 843) may not exist yet, or may
  # land after this view does — read defensively so this view never
  # needs to change again for that context to wire in. Expected
  # contract: `list_unacknowledged/1` returns every account-wide
  # pending schedule-change alert; filtered here to this cleaner's own.
  defp load_notifications(socket) do
    scope = socket.assigns.current_scope
    cleaner_id = scope.user.id

    notifications =
      if Code.ensure_loaded?(CleanerCrm.Notifications) and
           function_exported?(CleanerCrm.Notifications, :list_unacknowledged, 1) do
        scope
        |> CleanerCrm.Notifications.list_unacknowledged()
        |> Enum.filter(&(&1.cleaner_id == cleaner_id))
      else
        []
      end

    assign(socket, :notifications, notifications)
  end

  defp week_start(date), do: Date.add(date, -(Date.day_of_week(date) - 1))

  defp parse_date(nil), do: nil

  defp parse_date(string) do
    case Date.from_iso8601(string) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  defp format_time(time), do: Calendar.strftime(time, "%-H:%M")

  defp address(%{property: %{service_address: address}}) when is_binary(address), do: address
  defp address(_job), do: "No address on file"

  defp detail(%{property: property}, field, placeholder) do
    case property && Map.get(property, field) do
      value when is_binary(value) and value != "" -> value
      _ -> placeholder
    end
  end

  # Codes unlock strictly on the job's own real-world scheduled date —
  # never earlier, even while deliberately browsing that future day
  # via `?date=`. See criterion 7133's moduledoc: "a lockbox code
  # stays masked on a job card until the job's scheduled date arrives."
  defp unlocked?(%{scheduled_date: scheduled_date}), do: scheduled_date == Date.utc_today()

  defp mask_or_reveal(job, code) do
    if unlocked?(job), do: code, else: "••••"
  end
end
