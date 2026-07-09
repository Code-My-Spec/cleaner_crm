defmodule CleanerCrmWeb.TimesheetLive do
  @moduledoc """
  The owner's view of a pay period: every job with time recorded,
  what each cleaner is owed, which entries still need a clock-out
  before payroll can go out, and the CSV export.

  Route: `/app/timesheets`.
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Money
  alias CleanerCrm.Scheduling
  alias CleanerCrm.TimeTracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Timesheet
        <:subtitle>
          {Date.to_string(elem(@period, 0))} – {Date.to_string(elem(@period, 1))}
        </:subtitle>
        <:actions>
          <.button data-test="export-csv-button" phx-click="export" disabled={@unresolved?}>
            Export CSV
          </.button>
        </:actions>
      </.header>

      <p :if={@unresolved?} class="text-error mb-4">
        Resolve the unresolved time entry before exporting.
      </p>

      <div class="space-y-6">
        <div :for={cleaner <- @cleaners} class="card bg-base-100 border border-base-300">
          <div class="card-body">
            <h2 class="card-title text-base">{cleaner.name || cleaner.email}</h2>
            <p data-test={"cleaner-pay-total-#{cleaner.id}"}>
              Pay period total: {Money.format_cents(Map.get(@cleaner_totals, cleaner.id, 0))}
            </p>

            <ul class="list">
              <li
                :for={summary <- cleaner_summaries(@job_summaries, cleaner)}
                data-test={summary.unresolved? && "unresolved-entry-job-#{summary.job.id}"}
              >
                <span>{cleaner.email}</span>

                <span :if={!summary.unresolved?}>{Money.format_cents(summary.cents)}</span>

                <span :if={summary.open?}>
                  Missing clock-out
                  <.form
                    for={@resolve_form}
                    id={"resolve-form-#{summary.job.id}"}
                    data-test={"resolve-clock-out-form-#{summary.job.id}"}
                    phx-submit="resolve_clock_out"
                  >
                    <input type="hidden" name="time_entry[job_id]" value={summary.job.id} />
                    <.input
                      type="time"
                      name="time_entry[clock_out_time]"
                      value=""
                      label="Clock-out time"
                    />
                    <.button phx-disable-with="Resolving...">Resolve</.button>
                  </.form>
                </span>

                <span
                  :if={summary.unresolved? and !summary.open?}
                  data-test={"missing-pay-type-job-#{summary.job.id}"}
                >
                  Pay type not set for this job
                </span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    period = TimeTracking.current_pay_period(scope)

    {:ok,
     socket
     |> assign(:resolve_form, to_form(%{}, as: :time_entry))
     |> assign_period(scope, period)}
  end

  defp assign_period(socket, scope, period) do
    job_summaries = TimeTracking.list_job_time_summaries(scope, period)

    assign(socket,
      period: period,
      job_summaries: job_summaries,
      cleaners: job_summaries |> Enum.map(& &1.cleaner) |> Enum.uniq_by(& &1.id),
      cleaner_totals: TimeTracking.cleaner_pay_totals(scope, period),
      unresolved?: Enum.any?(job_summaries, & &1.unresolved?)
    )
  end

  defp cleaner_summaries(job_summaries, cleaner) do
    Enum.filter(job_summaries, &(&1.cleaner.id == cleaner.id))
  end

  @impl true
  def handle_event("export", _params, %{assigns: %{unresolved?: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("export", _params, socket) do
    {start_date, end_date} = socket.assigns.period

    {:noreply,
     redirect(socket,
       to:
         ~p"/app/timesheets/export?start_date=#{Date.to_iso8601(start_date)}&end_date=#{Date.to_iso8601(end_date)}"
     )}
  end

  def handle_event("resolve_clock_out", %{"time_entry" => %{"job_id" => job_id} = params}, socket) do
    scope = socket.assigns.current_scope
    job = Scheduling.get_job!(scope, job_id)

    socket =
      case TimeTracking.open_time_entry_for_job(scope, job) do
        nil ->
          socket

        entry ->
          case TimeTracking.resolve_clock_out(scope, entry, params) do
            {:ok, _entry} -> assign_period(socket, scope, socket.assigns.period)
            {:error, _changeset} -> socket
          end
      end

    {:noreply, socket}
  end
end
