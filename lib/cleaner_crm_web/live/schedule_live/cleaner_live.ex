defmodule CleanerCrmWeb.ScheduleLive.CleanerLive do
  @moduledoc """
  Adds a cleaner to the account's roster by name, so jobs and time off
  can be assigned to them.

  Not one of the schedule live-context's tracked components (only
  `Board`, `PlanFormComponent`, and `JobFormComponent` are) — added as
  minimal supporting scaffolding because every story 833 scenario
  needs a cleaner to exist first. See
  `CleanerCrmSpex.Fixtures.cleaner_fixture/3` for the fuller,
  login-capable path other stories seed cleaners through.
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.User

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@cleaner.name || @cleaner.email}
        <:subtitle>Cleaner</:subtitle>
        <:actions>
          <.button navigate={~p"/schedule/cleaners/#{@cleaner.id}/time-off/new"} variant="primary">
            Add Time Off
          </.button>
        </:actions>
      </.header>

      <div class="card bg-base-100 border border-base-300 mb-4">
        <div class="card-body">
          <h3 class="card-title text-sm">Time Off</h3>
          <p :if={@availability_blocks == []} class="text-sm opacity-70">
            No time off on file.
          </p>
          <ul :if={@availability_blocks != []} data-test="availability-blocks" class="list">
            <li
              :for={block <- @availability_blocks}
              data-test={"availability-block-#{block.id}"}
              class="list-row"
            >
              {block.date} — {if block.all_day,
                do: "All day",
                else: "#{block.start_time}-#{block.end_time}"}
            </li>
          </ul>
        </div>
      </div>

      <div class="card bg-base-100 border border-base-300">
        <div class="card-body">
          <h3 class="card-title text-sm">Upcoming Jobs</h3>
          <p :if={@upcoming_jobs == []} class="text-sm opacity-70">
            No upcoming jobs.
          </p>
          <ul :if={@upcoming_jobs != []} data-test="cleaner-upcoming-jobs" class="list">
            <li :for={job <- @upcoming_jobs} data-test={"cleaner-job-#{job.id}"} class="list-row">
              {job.scheduled_date} {job.start_time}-{job.end_time}
              <span :if={job.property}>— {job.property.service_address}</span>
            </li>
          </ul>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>New Cleaner</.header>

      <.form
        for={@form}
        id="cleaner-form"
        data-test="cleaner-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />

        <footer>
          <.button phx-disable-with="Saving...">Save Cleaner</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, :form, to_form(cleaner_changeset(%{}), as: :cleaner))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    scope = socket.assigns.current_scope
    cleaner = Scheduling.get_cleaner!(scope, id)

    socket
    |> assign(:cleaner, cleaner)
    |> assign(:availability_blocks, Scheduling.list_availability_blocks(scope, cleaner.id))
    |> assign(:upcoming_jobs, Scheduling.list_upcoming_jobs_for_cleaner(scope, cleaner.id))
  end

  @impl true
  def handle_event("validate", %{"cleaner" => params}, socket) do
    {:noreply,
     assign(socket, :form, to_form(cleaner_changeset(params), as: :cleaner, action: :validate))}
  end

  def handle_event("save", %{"cleaner" => %{"name" => name}}, socket) do
    case Scheduling.register_cleaner(socket.assigns.current_scope, name) do
      {:ok, user} ->
        {:noreply, push_navigate(socket, to: ~p"/schedule/cleaners/#{user.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :cleaner))}
    end
  end

  defp cleaner_changeset(params) do
    %User{}
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.validate_required([:name])
  end
end
