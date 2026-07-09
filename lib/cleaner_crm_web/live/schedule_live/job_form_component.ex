defmodule CleanerCrmWeb.ScheduleLive.JobFormComponent do
  @moduledoc """
  Create a single job, or assign/reassign a cleaner to an existing one.

  ## Assigns

  | Assign        | Type            | Required | Description                                          |
  |---------------|-----------------|----------|-------------------------------------------------------|
  | id            | string          | yes      | LiveComponent DOM id                                   |
  | current_scope | `Scope.t()`     | yes      | caller scope, used for all context calls               |
  | action        | `:new \\| :assign` | yes  | `:new` renders the full job form; `:assign` renders just the cleaner picker for an existing job |
  | job           | `Job.t()`       | yes      | blank `%Job{}` for `:new`, loaded job for `:assign`     |

  On a successful `:new` save, navigates itself to the new job's show
  page. On a successful `:assign`, sends `{__MODULE__, {:saved, job}}`
  to the parent instead (there's nowhere further to go — the parent
  just refreshes).

  Two more actions embed this same component inline on
  `CleanerCrmWeb.ScheduleLive.Index` (the board) rather than
  standalone: `:quick_new` (the board's own "New Job" button — same
  form as `:new`, but sends `{__MODULE__, {:job_created, job}}` to the
  parent instead of navigating away, since the point is to see the
  new job's brief on the board itself) and `:edit` (the board's
  per-job "Edit" button — reschedule and/or price change via
  `CleanerCrm.Scheduling.update_job/3`, sending
  `{__MODULE__, {:job_updated, job}}`). Neither touches
  `cleaner_id` — (re)assignment stays on the conflict-checked
  `:assign` path. When `:edit` moves the date, start time, or end
  time, it also pushes the same cleaner-facing schedule-change alert
  (story 843) that the board's own inline reschedule/cancel controls
  do, via `CleanerCrmWeb.ScheduleLive.ScheduleNotifier` — a
  pay-rate-only save stays silent.

  ## Dependencies

  - `CleanerCrm.Scheduling`
  - `CleanerCrmWeb.ScheduleLive.ScheduleNotifier`
  """

  use CleanerCrmWeb, :live_component

  import Ecto.Query, warn: false

  alias CleanerCrm.Clients.Property
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrmWeb.ScheduleLive.ScheduleNotifier

  @impl true
  def render(%{action: :assign} = assigns) do
    ~H"""
    <div id={@id}>
      <.header>Assign Cleaner</.header>

      <p :if={@conflict_error} data-test="assign-conflict-error" class="text-error mb-4">
        {@conflict_error}
      </p>

      <.form
        for={@form}
        id={"#{@id}-form"}
        data-test="assignment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:cleaner_id]}
          type="select"
          label="Cleaner"
          prompt="Unassigned"
          options={cleaner_options(@cleaners)}
        />

        <footer>
          <.button phx-disable-with="Assigning...">Assign Cleaner</.button>
        </footer>
      </.form>
    </div>
    """
  end

  def render(%{action: :edit} = assigns) do
    ~H"""
    <div id={@id}>
      <.header>Edit Job</.header>

      <.form
        for={@form}
        id={"#{@id}-form"}
        data-test="job-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          type="date"
          name="job[date]"
          id={@form[:scheduled_date].id}
          label="Date"
          value={@form[:scheduled_date].value}
          errors={field_errors(@form[:scheduled_date])}
        />
        <input type="text" name="job[scheduled_date]" value="" style="display:none" />
        <.input field={@form[:start_time]} type="time" label="Start Time" />
        <.input field={@form[:end_time]} type="time" label="End Time" />
        <.input field={@form[:agreed_price]} type="number" step="0.01" label="Price ($)" />
        <.pay_rate_inputs form={@form} pay_rate_input={@pay_rate_input} />

        <footer>
          <.button phx-disable-with="Saving...">Save Changes</.button>
        </footer>
      </.form>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.header>New Job</.header>

      <.form
        for={@form}
        id={"#{@id}-form"}
        data-test="job-form"
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
          type="date"
          name="job[date]"
          id={@form[:scheduled_date].id}
          label="Date"
          value={@form[:scheduled_date].value}
          errors={field_errors(@form[:scheduled_date])}
        />
        <input type="text" name="job[scheduled_date]" value="" style="display:none" />
        <.input field={@form[:start_time]} type="time" label="Start Time" />
        <.input field={@form[:end_time]} type="time" label="End Time" />
        <.input field={@form[:agreed_price]} type="number" step="0.01" label="Price ($)" />
        <.pay_rate_inputs form={@form} pay_rate_input={@pay_rate_input} />
        <.input
          field={@form[:cleaner_id]}
          type="select"
          label="Cleaner"
          prompt="Unassigned"
          options={cleaner_options(@cleaners)}
        />

        <footer>
          <.button phx-disable-with="Saving...">Save Job</.button>
        </footer>
      </.form>
    </div>
    """
  end

  # The pay-type select and its matching rate input, shared by the
  # `:new`/`:quick_new` and `:edit` forms (`:assign` never touches
  # pay). Only one rate input renders at a time, chosen by the form's
  # current `pay_type` — its raw dollar text lives in `@pay_rate_input`
  # rather than on the changeset, since `hourly_rate`/`piece_rate`
  # aren't real fields on `Job` (only the `_cents` columns are); the
  # dollar amount is converted to cents in `split_pay_params/1` before
  # it ever reaches the changeset.
  defp pay_rate_inputs(assigns) do
    ~H"""
    <.input
      field={@form[:pay_type]}
      type="select"
      label="Cleaner pay type"
      prompt="Not set"
      options={pay_type_options()}
    />
    <.input
      :if={pay_type_value(@form) == "hourly"}
      type="number"
      step="0.01"
      min="0"
      name="job[hourly_rate]"
      id={@form[:hourly_rate_cents].id}
      label="Hourly rate ($)"
      value={@pay_rate_input}
      errors={field_errors(@form[:hourly_rate_cents])}
    />
    <.input
      :if={pay_type_value(@form) == "piece_rate"}
      type="number"
      step="0.01"
      min="0"
      name="job[piece_rate]"
      id={@form[:piece_rate_cents].id}
      label="Piece rate ($)"
      value={@pay_rate_input}
      errors={field_errors(@form[:piece_rate_cents])}
    />
    """
  end

  @impl true
  def update(%{job: job, action: action} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:conflict_error, nil)
     |> assign(:properties, list_properties(assigns.current_scope))
     |> assign(:cleaners, Scheduling.list_cleaners(assigns.current_scope))
     |> assign(:pay_rate_input, initial_pay_rate_input(job))
     |> assign(:form, build_form(assigns.current_scope, job, action))}
  end

  defp build_form(scope, job, action) when action in [:new, :quick_new],
    do: to_form(Scheduling.change_job(scope, job), as: :job)

  defp build_form(scope, job, :edit),
    do: to_form(Scheduling.change_job(scope, with_display_price(job)), as: :job)

  defp build_form(scope, job, :assign),
    do: to_form(Scheduling.change_job(scope, job), as: :assignment)

  # `agreed_price` is virtual and isn't derived from the persisted
  # `agreed_price_cents` on load, so the edit form would otherwise
  # show a blank price for a job that already has one.
  defp with_display_price(%Job{agreed_price_cents: nil} = job), do: job

  defp with_display_price(%Job{agreed_price_cents: cents} = job),
    do: %{job | agreed_price: cents |> Decimal.new() |> Decimal.div(Decimal.new(100))}

  @impl true
  def handle_event("validate", %{"job" => params}, socket) do
    {pay_rate_input, params} = split_pay_params(params)

    changeset =
      socket.assigns.current_scope
      |> Scheduling.change_job(socket.assigns.job, params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:pay_rate_input, pay_rate_input)
     |> assign(:form, to_form(changeset, as: :job))}
  end

  def handle_event("validate", %{"assignment" => params}, socket) do
    changeset =
      socket.assigns.current_scope
      |> Scheduling.change_job(socket.assigns.job, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :assignment))}
  end

  # `:edit`, from the board's per-job "Edit" button: reschedule and/or
  # price change, staying put on the board.
  def handle_event("save", %{"job" => params}, %{assigns: %{action: :edit}} = socket) do
    {pay_rate_input, params} = split_pay_params(params)
    socket = assign(socket, :pay_rate_input, pay_rate_input)
    original = socket.assigns.job

    case Scheduling.update_job(socket.assigns.current_scope, original, params) do
      {:ok, job} ->
        notify_reschedule(socket.assigns.current_scope, original, job)
        notify_parent({:job_updated, job})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :job))}
    end
  end

  # `:quick_new`, from the board's own "New Job" button: same create as
  # `:new`, but notifies the parent instead of navigating away, so the
  # new job's brief shows up right there on the board.
  def handle_event("save", %{"job" => params}, %{assigns: %{action: :quick_new}} = socket) do
    {pay_rate_input, params} = split_pay_params(params)
    socket = assign(socket, :pay_rate_input, pay_rate_input)

    case Scheduling.create_job(socket.assigns.current_scope, params) do
      {:ok, job} ->
        notify_parent({:job_created, job})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :job))}
    end
  end

  # Navigates to the new job's show page directly (rather than
  # notifying the parent to decide) — a redirect issued from a parent's
  # `handle_info` in reaction to a component message lands one message
  # round-trip too late for `Phoenix.LiveViewTest.render_submit/1` to
  # observe it as a live redirect, which the board's own spex relies on.
  def handle_event("save", %{"job" => params}, socket) do
    {pay_rate_input, params} = split_pay_params(params)
    socket = assign(socket, :pay_rate_input, pay_rate_input)

    case Scheduling.create_job(socket.assigns.current_scope, params) do
      {:ok, job} ->
        {:noreply, push_navigate(socket, to: ~p"/schedule/jobs/#{job.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :job))}
    end
  end

  def handle_event("save", %{"assignment" => %{"cleaner_id" => cleaner_id}}, socket) do
    case Scheduling.assign_cleaner(
           socket.assigns.current_scope,
           socket.assigns.job,
           parse_id(cleaner_id)
         ) do
      {:ok, job} ->
        notify_parent({:saved, job})
        {:noreply, assign(socket, :conflict_error, nil)}

      {:error, :unavailable} ->
        {:noreply,
         assign(
           socket,
           :conflict_error,
           "This assignment has a scheduling conflict: the cleaner is unavailable that day."
         )}

      {:error, :overlap} ->
        {:noreply,
         assign(
           socket,
           :conflict_error,
           "This assignment was rejected: it overlaps another booking for this cleaner."
         )}
    end
  end

  defp parse_id(""), do: nil
  defp parse_id(nil), do: nil
  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
  defp parse_id(id) when is_integer(id), do: id

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  # Story 843: the "Edit Job" dialog needs the same cleaner-facing
  # alert the board's inline reschedule/cancel controls already push
  # (see `ScheduleLive.Index`) — otherwise a reschedule made through
  # this dialog leaves the cleaner never told. Only fires when a
  # schedule-relevant field actually changed; a pay-rate-only edit
  # (or any other no-op save) stays silent. `cleaner_id` never enters
  # into it — this dialog doesn't expose that field, per the
  # moduledoc above.
  defp notify_reschedule(scope, %Job{} = original, %Job{} = updated) do
    if schedule_changed?(original, updated) do
      ScheduleNotifier.notify_schedule_change(
        scope,
        updated,
        "Job moved from #{job_schedule_label(original)} to #{job_schedule_label(updated)}"
      )
    end
  end

  defp schedule_changed?(original, updated),
    do:
      original.scheduled_date != updated.scheduled_date or
        original.start_time != updated.start_time or
        original.end_time != updated.end_time

  defp job_schedule_label(%Job{} = job),
    do:
      "#{job.scheduled_date} #{ScheduleNotifier.format_time_12h(job.start_time)}-#{ScheduleNotifier.format_time_12h(job.end_time)}"

  defp list_properties(%{active_account_id: account_id}) do
    Property
    |> where([p], p.account_id == ^account_id)
    |> order_by([p], asc: p.service_address)
    |> Repo.all()
  end

  defp property_options(properties), do: Enum.map(properties, &{&1.service_address, &1.id})

  defp cleaner_options(cleaners), do: Enum.map(cleaners, &{&1.name || &1.email, &1.id})

  defp pay_type_options, do: [{"Hourly", "hourly"}, {"Piece rate", "piece_rate"}]

  defp pay_type_value(form) do
    case form[:pay_type].value do
      nil -> ""
      value -> to_string(value)
    end
  end

  # `hourly_rate`/`piece_rate` aren't real `Job` fields (only the
  # `_cents` columns are), so there's nothing on the changeset to
  # source a freshly-loaded job's dollar display from — this mirrors
  # `with_display_price/1` above, computed straight off whichever
  # `_cents` field matches the job's `pay_type`.
  defp initial_pay_rate_input(%Job{pay_type: :hourly, hourly_rate_cents: cents})
       when is_integer(cents),
       do: cents_to_dollars(cents)

  defp initial_pay_rate_input(%Job{pay_type: :piece_rate, piece_rate_cents: cents})
       when is_integer(cents),
       do: cents_to_dollars(cents)

  defp initial_pay_rate_input(%Job{}), do: ""

  defp cents_to_dollars(cents),
    do: cents |> Decimal.new() |> Decimal.div(Decimal.new(100)) |> Decimal.to_string(:normal)

  # Pulls the submitted dollar rate back out for redisplay (there's no
  # changeset field to read it from, per `initial_pay_rate_input/1`
  # above) and rewrites the matching `job[params]` key to
  # `*_rate_cents` before the changeset ever sees it — clearing the
  # other pay type's rate so switching pay types doesn't leave a
  # stale, unused rate behind.
  defp split_pay_params(%{"pay_type" => "hourly", "hourly_rate" => dollars} = params) do
    {dollars,
     params
     |> Map.put("hourly_rate_cents", dollars_to_cents(dollars))
     |> Map.put("piece_rate_cents", nil)}
  end

  defp split_pay_params(%{"pay_type" => "piece_rate", "piece_rate" => dollars} = params) do
    {dollars,
     params
     |> Map.put("piece_rate_cents", dollars_to_cents(dollars))
     |> Map.put("hourly_rate_cents", nil)}
  end

  defp split_pay_params(%{"pay_type" => ""} = params) do
    {"", params |> Map.put("hourly_rate_cents", nil) |> Map.put("piece_rate_cents", nil)}
  end

  defp split_pay_params(params), do: {"", params}

  # An unparseable dollar amount (or a blank input) becomes `nil`
  # rather than a changeset error — the rate is optional at the schema
  # level, same as `agreed_price`, so an invalid entry is treated as
  # "not set yet" rather than blocking the rest of the form.
  defp dollars_to_cents(dollars) when is_binary(dollars) do
    case Decimal.parse(String.trim(dollars)) do
      {decimal, ""} ->
        decimal |> Decimal.mult(100) |> Decimal.round(0, :half_up) |> Decimal.to_integer()

      _ ->
        nil
    end
  end

  defp dollars_to_cents(_dollars), do: nil

  defp field_errors(field) do
    if Phoenix.Component.used_input?(field),
      do: Enum.map(field.errors, &translate_error/1),
      else: []
  end
end
