defmodule CleanerCrmWeb.ScheduleLive.Index do
  @moduledoc """
  Weekly board of every cleaner's schedule, with unassigned jobs
  called out separately, inline reassignment, and inline job
  creation/editing/rescheduling/cancellation per job.

  Route: `/app/schedule`. Always shows the week containing today — there
  is no week navigation yet.
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrmWeb.ScheduleLive.{JobFormComponent, ScheduleNotifier}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Weekly Schedule
        <:subtitle>{length(@jobs)} jobs scheduled</:subtitle>
        <:actions>
          <.button data-test="new-job-button" phx-click="new_job" variant="primary">
            New Job
          </.button>
        </:actions>
      </.header>

      <p :if={@conflict_warning} data-test="schedule-conflict-warning" class="text-error mb-4">
        That reassignment conflicts with the cleaner's availability or another booking.
      </p>

      <p
        :if={@preferred_cleaner_warning}
        data-test="preferred-cleaner-warning"
        class="text-warning mb-4"
      >
        This visit is now assigned away from the client's preferred cleaner.
      </p>

      <div :if={@show_new_job_form} class="card bg-base-100 border border-base-300 mb-4">
        <div class="card-body">
          <.live_component
            module={JobFormComponent}
            id="new-job-form"
            current_scope={@current_scope}
            action={:quick_new}
            job={%Job{start_time: ~T[09:00:00], end_time: ~T[11:00:00]}}
          />
        </div>
      </div>

      <div
        data-test="weekly-board"
        class="grid gap-4"
        style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));"
      >
        <div
          :for={cleaner <- @cleaners}
          data-test={"cleaner-column-#{cleaner.id}"}
          class="card bg-base-100 border border-base-300"
        >
          <div class="card-body">
            <h3 class="card-title text-sm">{cleaner.name || cleaner.email}</h3>
            <.job_card
              :for={job <- jobs_for_cleaner(@jobs, cleaner.id)}
              job={job}
              cleaners={@cleaners}
              current_scope={@current_scope}
              editing_job_id={@editing_job_id}
            />
          </div>
        </div>

        <div data-test="unassigned-jobs" class="card bg-base-100 border border-base-300">
          <div class="card-body">
            <h3 class="card-title text-sm">Unassigned</h3>
            <.job_card
              :for={job <- unassigned_jobs(@jobs)}
              job={job}
              cleaners={@cleaners}
              current_scope={@current_scope}
              editing_job_id={@editing_job_id}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :job, :map, required: true
  attr :cleaners, :list, required: true
  attr :current_scope, :map, required: true
  attr :editing_job_id, :string, default: nil

  defp job_card(assigns) do
    ~H"""
    <div data-test="job-card">
      <div
        :if={@editing_job_id == @job.id}
        data-test={"job-#{@job.id}-edit-form"}
        class="border border-base-300 rounded p-2 mb-2"
      >
        <.live_component
          module={JobFormComponent}
          id={"edit-job-#{@job.id}"}
          current_scope={@current_scope}
          action={:edit}
          job={@job}
        />
      </div>

      <div
        :if={@editing_job_id != @job.id}
        data-test={"job-#{@job.id}"}
        class={["border-b border-base-200 py-2", @job.status == :cancelled && "opacity-50"]}
      >
        <span
          :if={@job.status == :cancelled}
          data-test={"job-#{@job.id}-cancelled-badge"}
          class="badge badge-sm"
        >
          Cancelled
        </span>

        <div class="text-sm">
          {@job.scheduled_date}
          <form id={"job-#{@job.id}-reschedule-form"} class="inline">
            <input
              type="time"
              data-test={"job-#{@job.id}-start-time-input"}
              name="start_time"
              value={@job.start_time}
              phx-change={"reschedule_job:#{@job.id}"}
            />
          </form>
          - {@job.end_time}
        </div>

        <div :if={status = reminder_status(@job)} class="text-xs font-semibold">
          {reminder_status_label(status)}
        </div>

        <div :if={@job.property} class="text-xs opacity-70">
          <div>{@job.property.service_address}</div>
          <div :if={@job.property.lockbox_code}>Lockbox: {@job.property.lockbox_code}</div>
          <div :if={@job.property.parking_notes}>Parking: {@job.property.parking_notes}</div>
          <div :if={@job.property.pet_notes}>Pets: {@job.property.pet_notes}</div>
        </div>

        <form id={"job-#{@job.id}-reassign-form"}>
          <select
            data-test={"job-#{@job.id}-cleaner-select"}
            name="cleaner_id"
            phx-change={"reassign_job:#{@job.id}"}
          >
            <option value="">Unassigned</option>
            <option
              :for={cleaner <- @cleaners}
              value={cleaner.id}
              selected={@job.cleaner_id == cleaner.id}
            >
              {cleaner.name || cleaner.email}
            </option>
          </select>
        </form>

        <div class="flex gap-2 mt-1">
          <button
            type="button"
            data-test={"job-#{@job.id}-edit-button"}
            phx-click={"edit_job:#{@job.id}"}
            class="btn btn-xs"
          >
            Edit
          </button>
          <button
            type="button"
            data-test={"job-#{@job.id}-cancel-button"}
            phx-click={"cancel_job:#{@job.id}"}
            class="btn btn-xs"
          >
            Cancel
          </button>
          <button
            type="button"
            data-test={"job-#{@job.id}-delete-button"}
            phx-click={"delete_job:#{@job.id}"}
            class="btn btn-xs btn-ghost"
          >
            Delete
          </button>
        </div>

        <div :if={alert = schedule_change_alert(@current_scope, @job)} class="text-xs mt-1">
          <span data-test={"job-#{@job.id}-ack-status"}>{ack_status_label(alert)}</span>
          <span data-test={"job-#{@job.id}-notification-channel"}>
            {channel_label(alert)} - {alert.change_summary}
          </span>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    week_start = week_start(Date.utc_today())

    {:ok,
     socket
     |> assign(:week_start, week_start)
     |> assign(:conflict_warning, nil)
     |> assign(:preferred_cleaner_warning, false)
     |> assign(:show_new_job_form, false)
     |> assign(:editing_job_id, nil)
     |> load_week()}
  end

  @impl true
  def handle_event("new_job", _params, socket) do
    {:noreply, assign(socket, :show_new_job_form, true)}
  end

  def handle_event("reassign_job:" <> job_id, %{"cleaner_id" => cleaner_id}, socket) do
    scope = socket.assigns.current_scope
    job = Scheduling.get_job!(scope, job_id)

    case Scheduling.assign_cleaner(scope, job, parse_id(cleaner_id)) do
      {:ok, updated} ->
        if updated.cleaner_id do
          ScheduleNotifier.notify_schedule_change(
            scope,
            updated,
            "Assigned to job on #{updated.scheduled_date} at #{ScheduleNotifier.format_time_12h(updated.start_time)}"
          )
        end

        {:noreply,
         socket
         |> assign(:conflict_warning, nil)
         |> assign(:preferred_cleaner_warning, deviates_from_preferred_cleaner?(scope, updated))
         |> load_week()}

      {:error, _reason} ->
        {:noreply, assign(socket, :conflict_warning, true)}
    end
  end

  def handle_event("edit_job:" <> job_id, _params, socket) do
    {:noreply, assign(socket, :editing_job_id, job_id)}
  end

  def handle_event("cancel_job:" <> job_id, _params, socket) do
    scope = socket.assigns.current_scope
    job = Scheduling.get_job!(scope, job_id)
    {:ok, _updated} = Scheduling.cancel_job(scope, job)
    ScheduleNotifier.notify_schedule_change(scope, job, "Cancelled")
    {:noreply, load_week(socket)}
  end

  def handle_event("delete_job:" <> job_id, _params, socket) do
    job = Scheduling.get_job!(socket.assigns.current_scope, job_id)
    {:ok, _updated} = Scheduling.delete_job(socket.assigns.current_scope, job)
    {:noreply, load_week(socket)}
  end

  def handle_event("reschedule_job:" <> job_id, %{"start_time" => start_time}, socket) do
    scope = socket.assigns.current_scope
    job = Scheduling.get_job!(scope, job_id)
    new_start = parse_time(start_time)
    new_end = Time.add(new_start, Time.diff(job.end_time, job.start_time), :second)

    case Scheduling.update_job(scope, job, %{start_time: new_start, end_time: new_end}) do
      {:ok, _updated} ->
        ScheduleNotifier.notify_schedule_change(
          scope,
          job,
          "Job moved from #{ScheduleNotifier.format_time_12h(job.start_time)} to #{ScheduleNotifier.format_time_12h(new_start)}"
        )

        {:noreply, load_week(socket)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({JobFormComponent, {:job_created, _job}}, socket) do
    {:noreply, socket |> assign(:show_new_job_form, false) |> load_week()}
  end

  def handle_info({JobFormComponent, {:job_updated, _job}}, socket) do
    {:noreply, socket |> assign(:editing_job_id, nil) |> load_week()}
  end

  defp load_week(socket) do
    scope = socket.assigns.current_scope

    socket
    |> assign(
      :jobs,
      Scheduling.list_jobs(scope, include_cancelled_ids: unacknowledged_cancelled_ids(scope))
    )
    |> assign(:cleaners, Scheduling.list_cleaners(scope))
  end

  # A cancelled job normally drops off the board entirely, but that
  # hides office visibility into whether the cleaner has acknowledged
  # the cancellation, and stops the read-time escalation check in
  # `CleanerCrm.Notifications.latest_schedule_change_for_job/2` from
  # ever running for it (issue 7df52070: it can sit "pending"
  # indefinitely). So a cancelled job whose latest schedule-change
  # notification isn't acknowledged yet stays on the board — see
  # `job_card`'s cancelled styling below — until it is.
  defp unacknowledged_cancelled_ids(scope) do
    if ScheduleNotifier.notifications_ready?(:job_ids_with_unacknowledged_schedule_change, 1) do
      CleanerCrm.Notifications.job_ids_with_unacknowledged_schedule_change(scope)
    else
      []
    end
  end

  # Story 846: a job materialized from a recurring plan carries that
  # plan's preferred cleaner as its default assignment (see
  # `CleanerCrm.Scheduling.Recurrence.job_attrs/1`). Reassigning it to
  # someone else always succeeds — this only flags the deviation for
  # the owner, it's a warning, never a block. A one-off job (no
  # `recurring_plan_id`) or a plan with no preference set (`cleaner_id`
  # nil) never warns, since there's nothing to deviate from.
  defp deviates_from_preferred_cleaner?(_scope, %Job{recurring_plan_id: nil}), do: false

  defp deviates_from_preferred_cleaner?(scope, %Job{} = job) do
    plan = Scheduling.get_recurring_plan!(scope, job.recurring_plan_id)
    not is_nil(plan.cleaner_id) and plan.cleaner_id != job.cleaner_id
  end

  defp week_start(date), do: Date.add(date, -(Date.day_of_week(date) - 1))

  defp jobs_for_cleaner(jobs, cleaner_id), do: Enum.filter(jobs, &(&1.cleaner_id == cleaner_id))
  defp unassigned_jobs(jobs), do: Enum.filter(jobs, &is_nil(&1.cleaner_id))

  defp parse_id(""), do: nil
  defp parse_id(nil), do: nil
  defp parse_id(id) when is_binary(id), do: String.to_integer(id)

  defp parse_time(str) when byte_size(str) == 5, do: Time.from_iso8601!(str <> ":00")
  defp parse_time(str), do: Time.from_iso8601!(str)

  # Expected contract: `latest_schedule_change_for_job(scope, job_id)`
  # returns `nil` or something map-like with `:status`
  # (`:pending` | `:acknowledged` | `:escalated`) and `:channel`
  # (`:push` | `:sms` | `:email`) keys, matching
  # `CleanerCrmSpex.Fixtures.schedule_change_notification_fixture/4`'s
  # shape.
  defp schedule_change_alert(scope, job) do
    if ScheduleNotifier.notifications_ready?(:latest_schedule_change_for_job, 2) do
      CleanerCrm.Notifications.latest_schedule_change_for_job(scope, job.id)
    end
  end

  defp ack_status_label(%{status: :pending}), do: "Unacknowledged"
  defp ack_status_label(%{status: :acknowledged}), do: "Acknowledged"
  defp ack_status_label(%{status: :escalated}), do: "Escalated"
  defp ack_status_label(_alert), do: "Unacknowledged"

  defp channel_label(%{channel: :push}), do: "Push"
  defp channel_label(%{channel: :sms}), do: "SMS"
  defp channel_label(%{channel: :email}), do: "Email"
  defp channel_label(_alert), do: "Push"

  # Expected contract: `reminder_status_for_job(job_id)` returns `nil`
  # (no decision yet), `:confirmed`, or `:reschedule_requested` — the
  # client's most recent decision on their appointment reminder.
  defp reminder_status(job) do
    if ScheduleNotifier.notifications_ready?(:reminder_status_for_job, 1) do
      CleanerCrm.Notifications.reminder_status_for_job(job.id)
    end
  end

  defp reminder_status_label(:confirmed), do: "Confirmed"
  defp reminder_status_label(:reschedule_requested), do: "Needs reschedule"
  defp reminder_status_label(_status), do: nil
end
