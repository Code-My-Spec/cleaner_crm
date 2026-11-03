defmodule CleanerCrmWeb.ScheduleLive.PlanFormComponent do
  @moduledoc """
  Create or edit a recurring plan, with series-wide conflict detection
  that updates live as the owner fills in the form.

  Saving a plan never blocks on conflicts — every occurrence still
  gets created and (if a preferred cleaner is set) still assigned to
  them. Conflicts stay visible after a save so the owner can keep
  reviewing/overriding them; this component intentionally does not
  navigate away on its own after saving (see `PlanLive`).

  ## Assigns

  | Assign        | Type                | Required | Description                                    |
  |---------------|---------------------|----------|-------------------------------------------------|
  | id            | string              | yes      | LiveComponent DOM id                             |
  | current_scope | `Scope.t()`         | yes      | caller scope, used for all context calls         |
  | action        | `:new \\| :edit`     | yes      | which mode the form is in                        |
  | plan          | `RecurringPlan.t()` | yes      | blank `%RecurringPlan{}` for `:new`, loaded for `:edit` |

  On successful save, sends `{__MODULE__, {:saved, plan}}` to the
  parent.

  ## Dependencies

  - `CleanerCrm.Scheduling`
  """

  use CleanerCrmWeb, :live_component

  import Ecto.Query, warn: false

  alias CleanerCrm.Clients.Property
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.RecurringPlan

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.header>{form_title(@action)}</.header>

      <.form
        for={@form}
        id={"#{@id}-form"}
        data-test="plan-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:property_id]}
          type="select"
          label="Property"
          prompt="Select a property"
          options={property_options(@properties)}
        />
        <.input
          field={@form[:cleaner_id]}
          type="select"
          label="Preferred Cleaner"
          prompt="No preferred cleaner"
          options={cleaner_options(@cleaners)}
        />
        <.input
          field={@form[:recurrence]}
          type="select"
          label="Recurrence"
          prompt="Select a cadence"
          options={[
            {"Weekly", "weekly"},
            {"Biweekly", "biweekly"},
            {"Every 3 weeks", "every_3_weeks"},
            {"Every 4 weeks", "monthly"}
          ]}
        />
        <.input field={@form[:start_date]} type="date" label="Start Date" />
        <.input field={@form[:occurrence_count]} type="number" label="Number of Visits" min="1" />
        <.input field={@form[:agreed_price]} type="number" step="0.01" label="Price ($)" />

        <div
          :for={conflict <- @conflicts}
          data-test={"conflict-visit-#{conflict.index}"}
          class="alert alert-warning mt-2"
        >
          <span>
            Visit {conflict.index} ({conflict.date}) has a scheduling conflict: {conflict_reason_text(
              conflict.reason
            )}.
          </span>
          <.button
            type="button"
            data-test={"override-conflict-#{conflict.index}"}
            phx-target={@myself}
            phx-click="override_conflict"
            phx-value-index={conflict.index}
          >
            Override
          </.button>
        </div>

        <footer class="mt-4">
          <.button
            type="button"
            data-test="save-plan-button"
            phx-target={@myself}
            phx-click="save"
            phx-disable-with="Saving..."
          >
            Save Plan
          </.button>
        </footer>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{plan: plan} = assigns, socket) do
    changeset =
      Scheduling.change_recurring_plan(assigns.current_scope, with_display_price(plan), %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:overridden, MapSet.new())
     |> assign(:properties, list_properties(assigns.current_scope))
     |> assign(:cleaners, Scheduling.list_cleaners(assigns.current_scope))
     |> assign_form_and_conflicts(changeset)}
  end

  @impl true
  def handle_event("validate", %{"plan" => params}, socket) do
    changeset =
      socket.assigns.current_scope
      |> Scheduling.change_recurring_plan(socket.assigns.plan, params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form_and_conflicts(socket, changeset)}
  end

  def handle_event("override_conflict", %{"index" => index}, socket) do
    index = String.to_integer(index)

    {:noreply,
     socket
     |> Phoenix.Component.update(:overridden, &MapSet.put(&1, index))
     |> Phoenix.Component.update(
       :conflicts,
       &Enum.reject(&1, fn conflict -> conflict.index == index end)
     )}
  end

  # The save button is a plain `phx-click`, not a form submit — the
  # board's own conflict-review flow drives it that way (see the
  # spex). It carries no params of its own, so it saves whatever the
  # last "validate" pass put in the form.
  def handle_event("save", %{"plan" => params}, socket), do: save_plan(socket, params)

  def handle_event("save", _params, socket),
    do: save_plan(socket, socket.assigns.form.params || %{})

  defp save_plan(socket, params) do
    case Scheduling.create_recurring_plan(socket.assigns.current_scope, params) do
      {:ok, {plan, _jobs}} ->
        notify_parent({:saved, plan})
        changeset = Scheduling.change_recurring_plan(socket.assigns.current_scope, plan, %{})

        {:noreply,
         socket
         |> assign(:plan, plan)
         |> assign_form_and_conflicts(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :plan))}
    end
  end

  defp assign_form_and_conflicts(socket, changeset) do
    draft = Ecto.Changeset.apply_changes(changeset)

    conflicts =
      socket.assigns.current_scope
      |> Scheduling.preview_conflicts(draft)
      |> Enum.reject(&MapSet.member?(socket.assigns.overridden, &1.index))

    socket
    |> assign(:form, to_form(changeset, as: :plan))
    |> assign(:conflicts, conflicts)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  # `agreed_price` is virtual and isn't derived from the persisted
  # `agreed_price_cents` on load, so editing an already-priced plan
  # would otherwise show a blank price field. Mirrors
  # `CleanerCrmWeb.ScheduleLive.JobFormComponent.with_display_price/1`.
  defp with_display_price(%RecurringPlan{agreed_price_cents: nil} = plan), do: plan

  defp with_display_price(%RecurringPlan{agreed_price_cents: cents} = plan),
    do: %{plan | agreed_price: cents |> Decimal.new() |> Decimal.div(Decimal.new(100))}

  defp list_properties(%{active_account_id: account_id}) do
    Property
    |> where([p], p.account_id == ^account_id)
    |> order_by([p], asc: p.service_address)
    |> Repo.all()
  end

  defp property_options(properties), do: Enum.map(properties, &{&1.service_address, &1.id})
  defp cleaner_options(cleaners), do: Enum.map(cleaners, &{&1.name || &1.email, &1.id})

  defp conflict_reason_text(:unavailable), do: "the cleaner is unavailable that day"
  defp conflict_reason_text(:overlap), do: "it overlaps another booking"

  defp form_title(:new), do: "New Recurring Plan"
  defp form_title(:edit), do: "Edit Recurring Plan"
end
