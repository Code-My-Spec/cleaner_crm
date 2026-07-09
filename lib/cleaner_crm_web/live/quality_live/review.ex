defmodule CleanerCrmWeb.QualityLive.Review do
  @moduledoc """
  Completed-job review with photos and checklist results, and the
  account's filed incident reports.

  ## Routes

    * `/app/quality` (`:index`) — every job (for picking one to review) and
      the account's incident reports, newest first, as the office's
      notification feed.
    * `/app/quality/:job_id` (`:show`) — one job's checklist, its
      timestamped before/after photos as proof of work, and the
      owner's quality rating.

  ## Dependencies

  - `CleanerCrm.Quality`
  - `CleanerCrm.Scheduling` (read-only: job lookups)
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Quality
  alias CleanerCrm.Scheduling

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@job.client && @job.client.name}
        <:subtitle>{@job.scheduled_date}</:subtitle>
        <:actions>
          <.button navigate={~p"/app/quality"} class="btn-sm btn-ghost">Back to Quality</.button>
        </:actions>
      </.header>

      <div :if={@checklist} class="space-y-6">
        <div class="card bg-base-100 border border-base-300">
          <div class="card-body space-y-2">
            <h3 class="font-semibold">Checklist</h3>

            <ul class="list">
              <li :for={item <- @checklist.items} class="list-row">
                <div class="list-col-grow">
                  <p>
                    <span :if={item.room} class="text-base-content/70">{item.room}:</span>
                    {item.task}
                    <span :if={item.checked} class="badge badge-success badge-sm">Done</span>
                    <span :if={item.skipped} class="badge badge-warning badge-sm">Skipped</span>
                  </p>

                  <p
                    :if={item.skipped}
                    data-test={"skip-reason-#{item.id}"}
                    class="text-sm text-warning"
                  >
                    Reason: {item.skip_reason}
                  </p>

                  <div :for={photo <- item.photos} class="text-sm text-base-content/70">
                    <span data-test="proof-of-work-photo">{photo.kind} photo: {photo.storage_key}</span>
                    <span :if={photo.captured_at} data-test="proof-of-work-photo-timestamp">
                      {DateTime.to_iso8601(photo.captured_at)}
                    </span>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>

        <div class="card bg-base-100 border border-base-300">
          <div class="card-body space-y-3">
            <h3 class="font-semibold">Quality</h3>

            <p data-test="quality-score">
              Score: {format_score(@checklist.quality_score)}
            </p>

            <form phx-submit="rate-job" data-test="quality-rating-form" class="flex items-end gap-2">
              <div class="fieldset">
                <label for="quality-rating-select">
                  <span class="label mb-1">Owner rating</span>
                  <select id="quality-rating-select" name="rating" class="select">
                    <option :for={n <- 1..5} value={n} selected={@checklist.owner_rating == n}>
                      {n}
                    </option>
                  </select>
                </label>
              </div>
              <.button type="submit" class="btn-sm">Rate</.button>
            </form>
          </div>
        </div>
      </div>

      <p :if={!@checklist} class="text-base-content/70">No checklist for this job yet.</p>
    </Layouts.app>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Quality
        <:subtitle>Job proof of work and incident reports</:subtitle>
        <:actions>
          <.button navigate={~p"/app/quality/scorecards"} class="btn-sm">Scorecards</.button>
        </:actions>
      </.header>

      <div
        :if={@incident_reports != []}
        data-test="incident-notification"
        class="alert alert-warning mb-6"
      >
        <span>{length(@incident_reports)} incident report(s) filed</span>
      </div>

      <div :if={@incident_reports != []} class="space-y-3 mb-8">
        <div
          :for={report <- @incident_reports}
          data-test="incident-report-item"
          class="card bg-base-100 border border-base-300"
        >
          <div class="card-body space-y-1">
            <p class="font-semibold">{report.job.client && report.job.client.name}</p>
            <p>{report.description}</p>
            <p class="text-sm text-base-content/70">
              <span data-test="incident-report-cleaner">{report.cleaner && report.cleaner.email}</span>
              &middot;
              <span data-test="incident-report-timestamp">{DateTime.to_iso8601(report.filed_at)}</span>
            </p>
          </div>
        </div>
      </div>

      <.header>Jobs</.header>

      <p :if={Enum.empty?(@jobs)} class="text-center py-8 text-base-content/70">No jobs yet.</p>

      <ul :if={Enum.any?(@jobs)} class="list">
        <li :for={job <- @jobs} class="list-row">
          <div class="list-col-grow">
            <.link navigate={~p"/app/quality/#{job.id}"} class="font-semibold link">
              {job.client && job.client.name}
            </.link>
            <p class="text-sm text-base-content/70">{job.scheduled_date} &middot; {job.status}</p>
          </div>
        </li>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(%{"job_id" => job_id}, _url, socket) do
    scope = socket.assigns.current_scope
    job = Scheduling.get_job!(scope, job_id)
    checklist = Quality.get_checklist_for_job(scope, job)

    {:noreply,
     socket
     |> assign(:page_title, "Review — #{job.client && job.client.name}")
     |> assign(:job, job)
     |> assign(:checklist, checklist)}
  end

  def handle_params(_params, _url, socket) do
    scope = socket.assigns.current_scope

    {:noreply,
     socket
     |> assign(:page_title, "Quality")
     |> assign(:jobs, Scheduling.list_jobs(scope))
     |> assign(:incident_reports, Quality.list_incident_reports(scope))}
  end

  @impl true
  def handle_event("rate-job", %{"rating" => rating}, socket) do
    {rating_int, _} = Integer.parse(rating)

    {:ok, checklist} =
      Quality.rate_job(socket.assigns.current_scope, socket.assigns.checklist, rating_int)

    {:noreply, assign(socket, :checklist, checklist)}
  end

  defp format_score(nil), do: "—"
  defp format_score(score), do: :erlang.float_to_binary(score * 1.0, decimals: 1)
end
