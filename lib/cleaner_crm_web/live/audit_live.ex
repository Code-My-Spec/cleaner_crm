defmodule CleanerCrmWeb.AuditLive do
  @moduledoc """
  Filterable audit trail for the account owner: who changed what, and
  when, narrowed by subject and date range.

  Read-only by design — the trail is append-only, so no edit or
  delete affordance is ever rendered here, regardless of who's
  viewing.

  Route: `/app/audit`.
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Accounts
  alias CleanerCrm.Audit
  alias CleanerCrm.Clients
  alias CleanerCrm.Scheduling

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Audit Trail
        <:subtitle>Who changed what, and when</:subtitle>
      </.header>

      <.form
        for={@filter_form}
        id="audit-filter-form"
        data-test="audit-filter-form"
        phx-change="filter"
      >
        <div class="grid gap-4" style="grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));">
          <.input field={@filter_form[:subject_id]} type="text" label="Subject ID" />
          <.input
            field={@filter_form[:actor]}
            type="select"
            label="Changed by"
            prompt="All"
            options={@actor_options}
            data-test="audit-filter-actor"
          />
          <.input
            field={@filter_form[:subject_type]}
            type="select"
            label="Record type"
            prompt="All"
            options={@subject_type_options}
            data-test="audit-filter-subject-type"
          />
          <.input field={@filter_form[:date_from]} type="date" label="From" />
          <.input field={@filter_form[:date_to]} type="date" label="To" />
        </div>
      </.form>

      <ul data-test="audit-entries" class="list mt-4">
        <li
          :for={entry <- @entries}
          data-test={"audit-entry-#{entry.id}"}
          class="list-row flex-col items-start"
        >
          <div>
            <strong>{actor_label(entry)}</strong>
            {humanize_action(entry.action)}
            {subject_label(@current_scope, entry)}
            <span class="opacity-60 text-sm">{format_timestamp(entry.inserted_at)}</span>
          </div>
          <div :for={line <- field_changes(entry)} class="text-sm opacity-80">{line}</div>
        </li>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    if owner?(scope) do
      {:ok,
       socket
       |> assign(:filter_form, to_form(%{}, as: :filter))
       |> assign(:actor_options, actor_options(scope))
       |> assign(:subject_type_options, subject_type_options(scope))
       |> assign(:entries, Audit.list_entries(scope, %{}))}
    else
      {:ok,
       socket
       |> put_flash(:error, "Only the account owner can view the audit trail.")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    entries = Audit.list_entries(socket.assigns.current_scope, query_filters(filter_params))

    {:noreply,
     socket
     |> assign(:filter_form, to_form(filter_params, as: :filter))
     |> assign(:entries, entries)}
  end

  defp owner?(scope),
    do: Accounts.get_user_role(scope, scope.user.id, scope.active_account_id) == :owner

  # The "actor" select collapses two underlying columns (actor_id, system)
  # into one filter choice — split it back out before querying.
  defp query_filters(filter_params) do
    filter_params
    |> Map.take(["subject_id", "subject_type", "date_from", "date_to"])
    |> Map.merge(actor_query_filter(filter_params["actor"]))
  end

  defp actor_query_filter("system"), do: %{"system" => true}
  defp actor_query_filter(blank) when blank in [nil, ""], do: %{}
  defp actor_query_filter(actor_id), do: %{"actor_id" => actor_id}

  defp actor_options(scope) do
    members = Accounts.list_account_members(scope, scope.active_account_id)

    user_options =
      members
      |> Enum.map(& &1.user)
      |> Enum.sort_by(& &1.email)
      |> Enum.map(&{&1.email, to_string(&1.id)})

    [{"System", "system"} | user_options]
  end

  defp subject_type_options(scope) do
    scope
    |> Audit.list_subject_types()
    |> Enum.map(&{&1, &1})
  end

  defp actor_label(%{system: true}), do: "System"
  defp actor_label(%{actor: %{email: email}}), do: email
  defp actor_label(_entry), do: "Unknown"

  defp humanize_action(action) do
    action
    |> String.replace_prefix("job_", "")
    |> String.replace_prefix("plan_", "")
    |> String.replace_prefix("property_", "")
    |> String.replace_prefix("client_", "")
    |> String.replace("_", " ")
  end

  defp format_timestamp(%DateTime{} = timestamp),
    do: Calendar.strftime(timestamp, "%Y-%m-%d %H:%M")

  defp subject_label(scope, %{subject_type: "Job", subject_id: id}),
    do: scope |> fetch_job(id) |> job_label(scope)

  defp subject_label(scope, %{subject_type: "Property", subject_id: id}),
    do: scope |> fetch_property(id) |> property_label(scope)

  defp subject_label(_scope, %{subject_type: type}), do: type

  defp fetch_job(scope, id) do
    Scheduling.get_job!(scope, id)
  rescue
    Ecto.NoResultsError -> nil
  end

  defp fetch_property(scope, id) do
    Clients.get_property!(scope, id)
  rescue
    Ecto.NoResultsError -> nil
  end

  defp job_label(nil, _scope), do: "a job"
  defp job_label(%{client: %CleanerCrm.Clients.Client{name: name}}, _scope), do: name

  defp job_label(%{property_id: property_id}, scope) when not is_nil(property_id),
    do: scope |> fetch_property(property_id) |> property_label(scope)

  defp job_label(_job, _scope), do: "a job"

  defp property_label(nil, _scope), do: "a job"

  defp property_label(%{client_id: client_id} = property, scope) do
    case Clients.get_client!(scope, client_id) do
      %{name: name} -> name
    end
  rescue
    Ecto.NoResultsError -> property.service_address
  end

  defp field_changes(%{old_value: old, new_value: new}) do
    (Map.keys(old) ++ Map.keys(new))
    |> Enum.uniq()
    |> Enum.map(&{&1, Map.get(old, &1), Map.get(new, &1), Map.has_key?(old, &1)})
    |> Enum.filter(fn {_field, old_v, new_v, _has_old?} -> old_v != new_v end)
    |> Enum.map(&format_change_line/1)
  end

  defp format_change_line({field, old_v, new_v, true}),
    do: "#{field_label(field)}: #{format_value(field, old_v)} → #{format_value(field, new_v)}"

  defp format_change_line({field, _old_v, new_v, false}),
    do: "#{field_label(field)}: #{format_value(field, new_v)}"

  defp field_label("scheduled_date"), do: "Scheduled date"
  defp field_label("start_time"), do: "Start time"
  defp field_label("end_time"), do: "End time"
  defp field_label("cleaner_id"), do: "Cleaner"
  defp field_label("agreed_price"), do: "Price"
  defp field_label("agreed_price_cents"), do: "Price"
  defp field_label("status"), do: "Status"

  defp field_label(field),
    do: field |> to_string() |> String.replace("_", " ") |> String.capitalize()

  defp format_value(field, value) when field in ["agreed_price", "agreed_price_cents"],
    do: format_price(field, value)

  defp format_value(_field, nil), do: "—"
  defp format_value(_field, value), do: to_string(value)

  defp format_price(_field, nil), do: "—"
  defp format_price("agreed_price_cents", cents) when is_integer(cents), do: money(cents / 100)
  defp format_price("agreed_price", %Decimal{} = amount), do: money(Decimal.to_float(amount))
  defp format_price("agreed_price", value) when is_number(value), do: money(value)

  defp format_price("agreed_price", value) when is_binary(value) do
    case Float.parse(value) do
      {amount, _rest} -> money(amount)
      :error -> value
    end
  end

  defp money(amount), do: "$" <> :erlang.float_to_binary(amount * 1.0, decimals: 2)
end
