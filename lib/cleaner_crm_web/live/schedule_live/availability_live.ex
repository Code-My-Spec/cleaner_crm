defmodule CleanerCrmWeb.ScheduleLive.AvailabilityLive do
  @moduledoc """
  Records a cleaner's time off (an all-day block, or a partial-day
  window) so the schedule board and conflict detector both know when
  that cleaner is unavailable.

  Not one of the schedule live-context's tracked components — added as
  minimal supporting scaffolding, same as `CleanerLive`.
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.AvailabilityBlock

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>New Time Off</.header>

      <.form
        for={@form}
        id="time-off-form"
        data-test="time-off-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:all_day]} type="checkbox" label="All day" />
        <.input field={@form[:start_time]} type="time" label="Start Time" />
        <.input field={@form[:end_time]} type="time" label="End Time" />

        <footer>
          <.button phx-disable-with="Saving...">Save Time Off</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"cleaner_id" => cleaner_id}, _session, socket) do
    changeset =
      Scheduling.change_availability_block(
        socket.assigns.current_scope,
        %AvailabilityBlock{cleaner_id: cleaner_id}
      )

    {:ok,
     socket
     |> assign(:cleaner_id, cleaner_id)
     |> assign(:form, to_form(changeset, as: :time_off))}
  end

  @impl true
  def handle_event("validate", %{"time_off" => params}, socket) do
    changeset =
      %AvailabilityBlock{cleaner_id: socket.assigns.cleaner_id}
      |> AvailabilityBlock.changeset(with_cleaner_id(socket, params))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :time_off))}
  end

  def handle_event("save", %{"time_off" => params}, socket) do
    case Scheduling.create_availability_block(
           socket.assigns.current_scope,
           with_cleaner_id(socket, params)
         ) do
      {:ok, block} ->
        {:noreply, push_navigate(socket, to: ~p"/schedule/cleaners/#{block.cleaner_id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :time_off))}
    end
  end

  defp with_cleaner_id(socket, params),
    do: Map.put(params, "cleaner_id", socket.assigns.cleaner_id)
end
