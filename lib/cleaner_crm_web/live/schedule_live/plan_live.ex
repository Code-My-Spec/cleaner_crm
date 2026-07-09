defmodule CleanerCrmWeb.ScheduleLive.PlanLive do
  @moduledoc """
  Routes for creating (`:new`) or editing (`:edit`) a recurring plan.
  Hosts `CleanerCrmWeb.ScheduleLive.PlanFormComponent`.
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.RecurringPlan
  alias CleanerCrmWeb.ScheduleLive.PlanFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={PlanFormComponent}
        id="plan-form"
        current_scope={@current_scope}
        action={@live_action}
        plan={@plan}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, :plan, %RecurringPlan{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    assign(socket, :plan, Scheduling.get_recurring_plan!(socket.assigns.current_scope, id))
  end

  # Saving intentionally does not navigate away — the form keeps
  # showing the created series' conflict flags for the owner to
  # review/override afterward (see `PlanFormComponent`).
  @impl true
  def handle_info({PlanFormComponent, {:saved, _plan}}, socket) do
    {:noreply, socket}
  end
end
