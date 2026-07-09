defmodule CleanerCrmWeb.PortalLive.Home do
  @moduledoc """
  Portal landing: upcoming visits with date/time and the named,
  photo-identified assigned cleaner; service history with checklist
  results and before/after photos per completed visit.

  Route: `/portal`, behind `CleanerCrmWeb.PortalAuth`'s magic-link
  session (`on_mount :require_client`) — no user login, so there is
  no `@current_scope` here.

  ## Dependencies

  - `CleanerCrm.Portal`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Portal

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>My Portal</.header>

      <div data-test="upcoming-visits" class="mb-8">
        <h2 class="text-lg font-semibold mb-2">Upcoming Visits</h2>

        <p :if={@upcoming_visits == []} class="text-base-content/70">
          No upcoming visits scheduled.
        </p>

        <.visit_summary_card :for={job <- @upcoming_visits} job={job} />
      </div>

      <div data-test="service-history">
        <h2 class="text-lg font-semibold mb-2">Service History</h2>

        <p :if={@visit_history == []} class="text-base-content/70">No completed visits yet.</p>

        <div
          :for={job <- @visit_history}
          data-test={"visit-#{job.id}"}
          class="card bg-base-100 border border-base-300 mb-3"
        >
          <div class="card-body">
            <div class="flex justify-between items-baseline">
              <span>{Calendar.strftime(job.scheduled_date, "%B %-d, %Y")}</span>
              <.link navigate={~p"/portal/visits/#{job.id}"} class="link link-primary text-sm">
                View details
              </.link>
            </div>

            <.checklist_proof checklist={Portal.visit_checklist(job)} />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :job, :map, required: true

  defp visit_summary_card(assigns) do
    ~H"""
    <div data-test={"visit-#{@job.id}"} class="card bg-base-100 border border-base-300 mb-3">
      <div class="card-body flex-row items-center gap-3">
        <.cleaner_identity cleaner={@job.cleaner} />

        <span class="ml-auto text-sm">
          {Calendar.strftime(@job.scheduled_date, "%B %-d")} at {format_time(@job.start_time)}
        </span>
      </div>
    </div>
    """
  end

  attr :cleaner, :map, default: nil

  defp cleaner_identity(%{cleaner: nil} = assigns) do
    ~H"""
    <span data-test="cleaner-not-assigned" class="opacity-70">Cleaner not yet assigned</span>
    """
  end

  defp cleaner_identity(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <div data-test="assigned-cleaner-photo" class="avatar avatar-placeholder">
        <div class="bg-neutral text-neutral-content rounded-full w-10">
          <span>{initials(@cleaner.name)}</span>
        </div>
      </div>
      <span>{@cleaner.name}</span>
    </div>
    """
  end

  attr :checklist, :map, default: nil

  defp checklist_proof(%{checklist: nil} = assigns) do
    ~H"""
    <p class="text-sm text-base-content/70 mt-2">No completed checklist recorded.</p>
    """
  end

  defp checklist_proof(assigns) do
    ~H"""
    <ul class="list mt-2">
      <li :for={item <- @checklist.items} class="list-row">
        {item.task}

        <img
          :for={photo <- photos_by_kind(item.photos, :before)}
          src={photo.storage_key}
          data-test="before-photo"
          class="w-16 h-16 object-cover rounded"
        />
        <img
          :for={photo <- photos_by_kind(item.photos, :after)}
          src={photo.storage_key}
          data-test="after-photo"
          class="w-16 h-16 object-cover rounded"
        />
      </li>
    </ul>
    """
  end

  defp photos_by_kind(photos, kind), do: Enum.filter(photos, &(&1.kind == kind))

  @impl true
  def mount(_params, _session, socket) do
    client = socket.assigns.client

    {:ok,
     socket
     |> assign(:page_title, "My Portal")
     |> assign(:upcoming_visits, Portal.list_upcoming_visits(client))
     |> assign(:visit_history, Portal.list_visit_history(client))}
  end

  defp initials(nil), do: "?"

  defp initials(name) do
    name
    |> String.split(" ", trim: true)
    |> Enum.map(&String.first/1)
    |> Enum.take(2)
    |> Enum.join()
    |> String.upcase()
  end

  defp format_time(%Time{} = time), do: Calendar.strftime(time, "%-I:%M %p")
end
