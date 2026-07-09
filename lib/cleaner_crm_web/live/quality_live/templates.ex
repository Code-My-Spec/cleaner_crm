defmodule CleanerCrmWeb.QualityLive.Templates do
  @moduledoc """
  Room-by-room checklist template management, per property — the
  office builds these so `CleanerCrm.Quality.create_checklist/4`
  (lazily called from `FieldLive.Job` the first time a cleaner opens
  a job with no checklist yet) can instantiate real, agreed-to tasks
  instead of an empty checklist.

  ## Routes

    * `/quality/templates` (`:index`)
    * `/quality/templates/new` (`:new`)
    * `/quality/templates/:id/edit` (`:edit`)

  ## Dependencies

  - `CleanerCrm.Quality`
  - `CleanerCrm.Clients` (read-only: the property picker)
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Clients
  alias CleanerCrm.Quality
  alias CleanerCrm.Quality.ChecklistTemplate
  alias CleanerCrmWeb.QualityLive.TemplateFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Checklist Templates
        <:subtitle>Room-by-room tasks the office has agreed to, per property</:subtitle>
        <:actions>
          <.button navigate={~p"/quality/templates/new"} variant="primary">
            <.icon name="hero-plus" class="size-4 mr-1" /> New Template
          </.button>
        </:actions>
      </.header>

      <div :if={@live_action in [:new, :edit]} class="card bg-base-100 border border-base-300 mb-6">
        <div class="card-body">
          <.live_component
            module={TemplateFormComponent}
            id={(@template && @template.id) || "new"}
            current_scope={@current_scope}
            action={@live_action}
            template={@template}
            properties={@properties}
          />
        </div>
      </div>

      <p :if={Enum.empty?(@templates)} class="text-center py-12 text-base-content/70">
        No checklist templates yet.
      </p>

      <.table :if={Enum.any?(@templates)} id="checklist-templates" rows={@templates}>
        <:col :let={template} label="Name">{template.name}</:col>
        <:col :let={template} label="Property">{property_label(template)}</:col>
        <:col :let={template} label="Tasks">{length(template.items)}</:col>
        <:action :let={template}>
          <.link
            navigate={~p"/quality/templates/#{template.id}/edit"}
            data-test={"edit-template-#{template.id}"}
            class="btn btn-sm btn-ghost"
          >
            Edit
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:templates, Quality.list_checklist_templates(scope))
     |> assign(:properties, properties_for_picker(scope))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Checklist Templates")
    |> assign(:template, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Checklist Template")
    |> assign(:template, %ChecklistTemplate{items: []})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    template = Quality.get_checklist_template!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit #{template.name}")
    |> assign(:template, template)
  end

  defp property_label(%ChecklistTemplate{property_id: nil}), do: "Any property"
  defp property_label(%ChecklistTemplate{property: property}), do: property.service_address

  defp properties_for_picker(scope) do
    for client <- Clients.list_active_clients(scope),
        property <- Clients.list_properties(scope, client) do
      {"#{client.name} — #{property.service_address}", property.id}
    end
  end
end
