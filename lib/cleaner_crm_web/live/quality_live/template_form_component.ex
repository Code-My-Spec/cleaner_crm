defmodule CleanerCrmWeb.QualityLive.TemplateFormComponent do
  @moduledoc """
  Create/edit a `CleanerCrm.Quality.ChecklistTemplate`: its name, an
  optional property, and its room-by-room task rows — added and
  removed with Ecto's `embeds_many` sort/drop params (see
  `ChecklistTemplate.changeset/2`).

  On successful save, navigates to the template list directly
  (rather than notifying the parent), matching
  `CleanerCrmWeb.ClientLive.FormComponent`'s approach.

  ## Assigns

  | Assign        | Type               | Description                                |
  |---------------|--------------------|--------------------------------------------|
  | id            | string             | LiveComponent DOM id                        |
  | current_scope | `Scope.t()`        | caller scope, used for all context calls    |
  | action        | `:new \\| :edit`   | which mode the form is in                   |
  | template      | `ChecklistTemplate.t()` | blank (with `items: []`) for `:new`, loaded for `:edit` |
  | properties    | `[{label, id}]`    | options for the property picker             |

  ## Dependencies

  - `CleanerCrm.Quality`
  """

  use CleanerCrmWeb, :live_component

  alias CleanerCrm.Quality

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.header>{form_title(@action)}</.header>

      <.form
        for={@form}
        id={"#{@id}-form"}
        data-test="checklist-template-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" data-test="template-name-input" />

        <.input
          field={@form[:property_id]}
          type="select"
          label="Property"
          prompt="Any property"
          options={@properties}
          data-test="template-property-select"
        />

        <div class="mt-4 space-y-3" data-test="template-items">
          <h3 class="font-semibold">Tasks</h3>

          <.inputs_for :let={item_form} field={@form[:items]}>
            <input type="hidden" name={"#{@form.name}[items_sort][]"} value={item_form.index} />

            <div
              class="flex items-end gap-2 border-b border-base-300 pb-2"
              data-test={"template-item-#{item_form.index}"}
            >
              <.input field={item_form[:room]} label="Room" placeholder="Kitchen" />
              <.input field={item_form[:task]} label="Task" placeholder="Counters wiped down" />
              <.input field={item_form[:required]} type="checkbox" label="Required" />

              <label class="btn btn-sm btn-ghost">
                <input
                  type="checkbox"
                  name={"#{@form.name}[items_drop][]"}
                  value={item_form.index}
                  class="hidden"
                /> Remove
              </label>
            </div>
          </.inputs_for>

          <input type="hidden" name={"#{@form.name}[items_drop][]"} />

          <label class="btn btn-sm" data-test="add-template-item-button">
            <input
              type="checkbox"
              name={"#{@form.name}[items_sort][]"}
              value="new"
              class="hidden"
            /> Add Task
          </label>
        </div>

        <footer class="mt-6">
          <.button
            phx-disable-with="Saving..."
            variant="primary"
            data-test="save-template-button"
          >
            Save Template
          </.button>
        </footer>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{template: template} = assigns, socket) do
    changeset = Quality.change_checklist_template(assigns.current_scope, template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset, as: :template))}
  end

  @impl true
  def handle_event("validate", %{"template" => template_params}, socket) do
    changeset =
      socket.assigns.current_scope
      |> Quality.change_checklist_template(socket.assigns.template, template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :template))}
  end

  def handle_event("save", %{"template" => template_params}, socket) do
    save_template(socket, socket.assigns.action, template_params)
  end

  defp save_template(socket, :new, params) do
    case Quality.create_checklist_template(socket.assigns.current_scope, params) do
      {:ok, _template} ->
        {:noreply, push_navigate(socket, to: ~p"/app/quality/templates")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_template(socket, :edit, params) do
    case Quality.update_checklist_template(
           socket.assigns.current_scope,
           socket.assigns.template,
           params
         ) do
      {:ok, _template} ->
        {:noreply, push_navigate(socket, to: ~p"/app/quality/templates")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp form_title(:new), do: "New Checklist Template"
  defp form_title(:edit), do: "Edit Checklist Template"
end
