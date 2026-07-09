defmodule CleanerCrmWeb.PortalLive.Visit do
  @moduledoc """
  Single visit detail: reschedule (pick a new date/time) and cancel,
  both gated by the account's cancellation policy — any late or
  same-day fee is shown before the client confirms cancelling.
  Completed or already-cancelled visits offer neither control.

  Route: `/portal/visits/:id`, behind `CleanerCrmWeb.PortalAuth`'s
  magic-link session.

  ## Dependencies

  - `CleanerCrm.Portal`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Money
  alias CleanerCrm.Portal
  alias CleanerCrmWeb.ScheduleLive.ScheduleNotifier

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} variant={:portal}>
      <.header>Visit on {Calendar.strftime(@job.scheduled_date, "%B %-d, %Y")}</.header>

      <div class="space-y-1 mb-6">
        <p>
          <span class="font-medium">Time:</span>
          {ScheduleNotifier.format_time_12h(@job.start_time)} - {ScheduleNotifier.format_time_12h(
            @job.end_time
          )}
        </p>
        <p>
          <span class="font-medium">Cleaner:</span>
          <span data-test="visit-cleaner-name">{cleaner_name(@job)}</span>
        </p>
        <p>
          <span class="font-medium">Price:</span>
          <span data-test="visit-price">{Money.format_cents(@job.agreed_price_cents)}</span>
        </p>
        <p data-test="visit-status">Status: {status_label(@job.status)}</p>
      </div>

      <div :if={@job.status == :cancelled} data-test="visit-cancelled-notice" class="mb-4">
        <span
          :if={@fee_charged_cents && @fee_charged_cents > 0}
          data-test="cancellation-fee-charged"
        >
          {Money.format_cents(@fee_charged_cents)} cancellation fee charged.
        </span>
      </div>

      <div :if={modifiable?(@job)}>
        <.form
          for={@reschedule_form}
          data-test="reschedule-form"
          phx-submit="reschedule"
          class="flex gap-2 items-end mb-6"
        >
          <.input field={@reschedule_form[:date]} type="date" label="New date" />
          <.input field={@reschedule_form[:start_time]} type="time" label="New start time" />
          <.button type="submit" variant="primary">Reschedule</.button>
        </.form>

        <button
          type="button"
          data-test="cancel-visit-button"
          phx-click="start_cancel"
          class="btn btn-error btn-sm"
        >
          Cancel visit
        </button>

        <div :if={@confirming_cancel} class="mt-2">
          <p
            :if={@cancellation_fee_cents > 0}
            data-test="cancellation-fee-notice"
            class="text-warning"
          >
            Cancelling now will charge a {Money.format_cents(@cancellation_fee_cents)} fee.
          </p>
          <button
            type="button"
            data-test="confirm-cancel-button"
            phx-click="confirm_cancel"
            class="btn btn-error btn-sm"
          >
            Confirm cancellation
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    client = socket.assigns.client
    job = Portal.get_visit!(client, id)

    {:ok,
     socket
     |> assign(:page_title, "Visit")
     |> assign(:client, client)
     |> assign(:job, job)
     |> assign(:confirming_cancel, false)
     |> assign(:fee_charged_cents, nil)
     |> assign(:cancellation_fee_cents, Portal.cancellation_fee_cents(client, job))
     |> assign_reschedule_form(job)}
  end

  @impl true
  def handle_event("reschedule", %{"visit" => params}, socket) do
    case Portal.reschedule_visit(socket.assigns.client, socket.assigns.job, params) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:job, updated)
         |> assign(
           :cancellation_fee_cents,
           Portal.cancellation_fee_cents(socket.assigns.client, updated)
         )
         |> assign_reschedule_form(updated)}

      {:error, :not_modifiable} ->
        {:noreply, put_flash(socket, :error, "This visit can no longer be changed.")}

      {:error, :slot_in_past} ->
        {:noreply, assign(socket, :reschedule_form, slot_in_past_form(params))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :reschedule_form, to_form(changeset, as: :visit))}
    end
  end

  def handle_event("start_cancel", _params, socket) do
    {:noreply, assign(socket, :confirming_cancel, true)}
  end

  def handle_event("confirm_cancel", _params, socket) do
    case Portal.cancel_visit(socket.assigns.client, socket.assigns.job) do
      {:ok, updated, fee_cents} ->
        {:noreply,
         socket
         |> assign(:job, updated)
         |> assign(:confirming_cancel, false)
         |> assign(:fee_charged_cents, fee_cents)}

      {:error, :not_modifiable} ->
        {:noreply, put_flash(socket, :error, "This visit can no longer be changed.")}
    end
  end

  defp assign_reschedule_form(socket, job) do
    assign(
      socket,
      :reschedule_form,
      to_form(%{"date" => job.scheduled_date, "start_time" => format_input_time(job.start_time)},
        as: :visit
      )
    )
  end

  defp format_input_time(%Time{} = time), do: time |> Time.to_string() |> String.slice(0, 5)

  # Rebuilds the reschedule form around what the client actually
  # submitted (so the invalid values stay visible) with a field-level
  # error attached — `:date` if the date itself is already past today,
  # `:start_time` if it's today but the time has already passed —
  # mirroring `CleanerCrm.Booking.Lead`'s own two error messages for
  # the same distinction.
  defp slot_in_past_form(%{"date" => date_input} = params) do
    {field, message} =
      case Date.from_iso8601(date_input) do
        {:ok, date} ->
          if Date.compare(date, Date.utc_today()) == :lt do
            {:date, "must be today or later"}
          else
            {:start_time, "must be later than the current time"}
          end

        :error ->
          {:date, "must be today or later"}
      end

    to_form(params, as: :visit, errors: [{field, {message, []}}])
  end

  defp modifiable?(%{status: status}), do: status not in [:completed, :cancelled]

  defp cleaner_name(%{cleaner: %{name: name}}) when is_binary(name) and name != "", do: name
  defp cleaner_name(%{cleaner: %{email: email}}) when is_binary(email), do: email
  defp cleaner_name(_job), do: "Not yet assigned"

  defp status_label(:scheduled), do: "Scheduled"
  defp status_label(:in_progress), do: "In progress"
  defp status_label(:completed), do: "Completed"
  defp status_label(:cancelled), do: "Cancelled"
end
