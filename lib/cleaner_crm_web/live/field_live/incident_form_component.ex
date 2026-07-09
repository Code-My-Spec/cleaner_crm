defmodule CleanerCrmWeb.FieldLive.IncidentFormComponent do
  @moduledoc """
  Files a damage, missing-item, or unsafe-condition report from the
  job screen, and lists reports already filed for this job.

  A photo is required for damage/missing-item reports (enforced by
  `CleanerCrm.Quality.file_incident_report/3`'s own changeset, not
  duplicated here); unsafe-condition reports need none. Once filed, a
  report is immutable — this component never offers an edit or delete
  affordance.

  ## Assigns

  | Assign        | Type        | Required | Description                |
  |---------------|-------------|----------|------------------------------|
  | id            | string      | yes      | LiveComponent DOM id          |
  | current_scope | `Scope.t()` | yes      | caller scope                  |
  | job           | `Job.t()`   | yes      | the job being reported on     |

  ## Dependencies

  - `CleanerCrm.Quality`
  """

  use CleanerCrmWeb, :live_component

  alias CleanerCrm.Quality
  alias CleanerCrm.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="card bg-base-100 border border-base-300 mb-4">
      <div class="card-body">
        <h3 class="card-title text-sm">Report an Issue</h3>

        <.form
          for={@form}
          id={"#{@id}-form"}
          data-test="incident-report-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input
            field={@form[:type]}
            type="select"
            label="Type"
            prompt="Select a type"
            options={[
              {"Damage", "damage"},
              {"Missing item", "missing_item"},
              {"Unsafe condition", "unsafe_condition"}
            ]}
          />
          <.input field={@form[:description]} type="textarea" label="Description" />

          <div data-test="incident-photo-upload" phx-target={@myself}>
            <span class="label mb-1">Photo (required for damage or a missing item)</span>
            <.live_file_input upload={@uploads.photo} />
          </div>

          <p :for={msg <- photo_errors(@form)} class="text-error text-sm">{msg}</p>

          <footer>
            <.button phx-disable-with="Filing...">File Report</.button>
          </footer>
        </.form>

        <ul :if={@incident_reports != []} class="mt-4">
          <li
            :for={report <- @incident_reports}
            data-test="incident-report-item"
            class="border-b border-base-200 py-2 text-sm"
          >
            <span class="badge badge-ghost badge-sm">{report.type}</span>
            <p>{report.description}</p>
            <p data-test="incident-report-cleaner" class="text-xs opacity-70">
              {report.cleaner.email}
            </p>
            <p data-test="incident-report-timestamp" class="text-xs opacity-70">
              {Calendar.strftime(report.filed_at, "%Y-%m-%d %H:%M")}
            </p>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, allow_upload(socket, :photo, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> blank_form() end)
     |> assign_new(:incident_reports, fn ->
       load_incident_reports(assigns.current_scope, assigns.job)
     end)}
  end

  defp blank_form, do: to_form(%{"type" => nil, "description" => nil}, as: :incident)

  defp load_incident_reports(scope, job) do
    scope
    |> Quality.list_incident_reports()
    |> Enum.filter(&(&1.job_id == job.id))
  end

  @impl true
  def handle_event("validate", %{"incident" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :incident))}
  end

  @impl true
  def handle_event("save", %{"incident" => params}, socket) do
    attrs = maybe_put_photo(params, socket)

    case Quality.file_incident_report(socket.assigns.current_scope, socket.assigns.job, attrs) do
      {:ok, report} ->
        report = Repo.preload(report, :cleaner)

        {:noreply,
         socket
         |> assign(:incident_reports, [report | socket.assigns.incident_reports])
         |> assign(:form, blank_form())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :incident))}
    end
  end

  defp maybe_put_photo(params, socket) do
    case socket.assigns.uploads.photo.entries do
      [] ->
        params

      _entries ->
        [storage_key] =
          consume_uploaded_entries(socket, :photo, fn %{path: path}, entry ->
            {:ok, store_upload!(path, entry)}
          end)

        Map.put(params, "photo", %{
          "storage_key" => storage_key,
          "upload_state" => "uploaded",
          "captured_at" => DateTime.utc_now()
        })
    end
  end

  defp store_upload!(path, entry) do
    dest_dir = Path.join([:code.priv_dir(:cleaner_crm), "static", "uploads"])
    File.mkdir_p!(dest_dir)
    filename = "#{System.unique_integer([:positive])}-#{entry.client_name}"
    File.cp!(path, Path.join(dest_dir, filename))
    "/uploads/#{filename}"
  end

  defp photo_errors(%{source: %Ecto.Changeset{} = changeset}) do
    changeset.errors
    |> Keyword.get_values(:photo)
    |> Enum.map(fn {msg, _opts} -> "A photo " <> msg <> "." end)
  end

  defp photo_errors(_form), do: []
end
