defmodule CleanerCrmWeb.ScheduleLive.JobLive do
  @moduledoc """
  Routes for a single job: create one (`:new`), assign or reassign its
  cleaner (`:assign`), and view its details (`:show`).

  Hosts `CleanerCrmWeb.ScheduleLive.JobFormComponent` for `:new` and
  `:assign`; `:show` is a plain detail page.
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrmWeb.ScheduleLive.JobFormComponent

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>Job Details</.header>

      <ul class="list">
        <li><strong>Property:</strong> {@job.property && @job.property.service_address}</li>
        <li><strong>Date:</strong> {@job.scheduled_date}</li>
        <li><strong>Time:</strong> {@job.start_time} - {@job.end_time}</li>
        <li data-test="job-cleaner">
          <strong>Cleaner:</strong> {cleaner_label(@job.cleaner)}
        </li>
        <li><strong>Status:</strong> {@job.status}</li>
      </ul>

      <.button
        :if={@job.status != :cancelled}
        data-test={"job-#{@job.id}-cancel-button"}
        phx-click="cancel"
      >
        Cancel Job
      </.button>
    </Layouts.app>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={JobFormComponent}
        id="job-form"
        current_scope={@current_scope}
        action={@live_action}
        job={@job}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, :job, %Job{})
  end

  defp apply_action(socket, action, %{"id" => id}) when action in [:assign, :show] do
    assign(socket, :job, Scheduling.get_job!(socket.assigns.current_scope, id))
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    case Scheduling.cancel_job(socket.assigns.current_scope, socket.assigns.job) do
      {:ok, job} -> {:noreply, assign(socket, :job, job)}
    end
  end

  # Only `:assign` notifies the parent (see `JobFormComponent`) — `:new`
  # navigates itself straight to the show page.
  @impl true
  def handle_info({JobFormComponent, {:saved, job}}, socket) do
    {:noreply, assign(socket, :job, Scheduling.get_job!(socket.assigns.current_scope, job.id))}
  end

  defp cleaner_label(nil), do: "Unassigned"
  defp cleaner_label(cleaner), do: cleaner.name || cleaner.email
end
