defmodule CleanerCrmWeb.BookingLive.Accept do
  @moduledoc """
  Token-link quote acceptance (story 849): the locked price recap,
  slot selection, cancellation-policy agreement, and card capture that
  converts a `CleanerCrm.Booking.Lead` into a client + property +
  plan/job and issues portal access.

  Mounted as the `:accept` `live_action` of
  `CleanerCrmWeb.BookingLive.Quote` rather than routed on its own —
  see that module's moduledoc for why (`push_patch/2` only navigates
  within the currently-mounted view module, and the calculator patches
  here once contact info locks in a price). Every function below still
  only ever touches `CleanerCrm.Booking`.

  ## Dependencies

  - `CleanerCrm.Booking`
  """

  use CleanerCrmWeb, :html

  alias CleanerCrm.Booking
  alias CleanerCrm.Booking.Lead
  alias CleanerCrm.Money

  @doc "Loads the lead for `token` and sets up whichever step it's currently at."
  def mount(token, socket) do
    case Booking.get_lead_by_token(token) do
      nil ->
        socket
        |> assign(:page_title, "Booking not found")
        |> assign(:step, :not_found)
        |> assign(:lead, nil)

      %Lead{} = lead ->
        socket
        |> assign(:page_title, "Confirm your booking")
        |> assign(:lead, lead)
        |> assign(:slot_form, to_form(Booking.change_slot(lead), as: :booking))
        |> assign(:confirmation_form, to_form(Booking.change_confirmation(lead), as: :booking))
        |> assign(:slot_unavailable, false)
        |> assign(:policy_required, false)
        |> assign(:step, step_for(lead))
    end
  end

  defp step_for(%Lead{status: :converted}), do: :confirmed
  defp step_for(%Lead{status: :payment_pending}), do: :payment_pending
  defp step_for(%Lead{status: :payment_declined}), do: :payment_declined
  defp step_for(%Lead{scheduled_date: nil}), do: :select_slot
  defp step_for(%Lead{}), do: :confirm

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Confirm your booking</.header>

      <p :if={@step == :not_found}>
        We couldn't find that booking link. It may have expired — please request a new quote.
      </p>

      <div :if={@step != :not_found} class="card bg-base-100 border border-base-300 mb-4">
        <div class="card-body">
          <h2 class="card-title">Your price</h2>
          <p class="text-lg font-semibold" data-test="locked-total">
            {Money.format_cents(@lead.total_cents)}
          </p>
          <p class="text-sm text-base-content/70">
            Locked in from your instant quote — no added fees.
          </p>
        </div>
      </div>

      <div :if={@step == :confirmed} data-test="booking-confirmed" class="alert alert-success">
        <span>
          You're booked for {format_date(@lead.scheduled_date)} at {format_time(@lead.start_time)}.
          Check your email for a link to your client portal.
        </span>
      </div>

      <div :if={@step == :payment_pending} data-test="payment-pending" class="alert alert-info">
        <span>Confirming your payment — this page will update as soon as it's done.</span>
      </div>

      <div :if={@step not in [:not_found, :confirmed, :payment_pending]}>
        <div
          :if={@step == :payment_declined}
          data-test="payment-declined-message"
          class="alert alert-error mb-4"
        >
          <span>Your card was declined. Please try a different card below.</span>
        </div>

        <div :if={@slot_unavailable} data-test="slot-unavailable-error" class="alert alert-error mb-4">
          <span>That time was just booked by someone else — please pick another slot.</span>
        </div>

        <.form
          :if={@step == :select_slot}
          for={@slot_form}
          id="slot-form"
          data-test="slot-form"
          phx-submit="select_slot"
        >
          <.input field={@slot_form[:scheduled_date]} type="date" label="Date" />
          <.input field={@slot_form[:start_time]} type="time" label="Start time" />

          <footer class="flex justify-end mt-4">
            <.button phx-disable-with="Checking...">Continue</.button>
          </footer>
        </.form>

        <.form
          :if={@step in [:confirm, :payment_declined]}
          for={@confirmation_form}
          id="confirmation-form"
          data-test="confirmation-form"
          phx-submit="confirm_booking"
        >
          <p class="text-sm mb-2">
            Cancellation policy: cancel or reschedule at least 24-hour ahead of your visit to
            avoid a late-cancellation fee.
          </p>

          <.input
            field={@confirmation_form[:policy_agreed]}
            type="checkbox"
            label="I agree to the cancellation policy"
            data-test="policy-agreement-checkbox"
          />
          <p :if={@policy_required} data-test="policy-required-error" class="text-sm text-error">
            Please agree to the cancellation policy to continue.
          </p>

          <%!--
            Real card capture (Stripe Elements) is deferred — this
            mirrors the existing `/pay/:token` payment page's own
            simplification, a single test card baked in as a hidden
            field until Elements lands.
          --%>
          <input type="hidden" name="booking[payment_method]" value="pm_card_visa" />

          <footer class="flex justify-end mt-4">
            <.button phx-disable-with="Booking...">
              Confirm & pay {Money.format_cents(@lead.total_cents)}
            </.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("select_slot", %{"booking" => params}, socket) do
    case Booking.select_slot(socket.assigns.lead, params) do
      {:ok, slotted_lead} ->
        {:noreply, socket |> assign(:lead, slotted_lead) |> assign(:step, :confirm)}

      {:error, changeset} ->
        {:noreply, assign(socket, :slot_form, to_form(changeset, as: :booking))}
    end
  end

  def handle_event("confirm_booking", %{"booking" => params}, socket) do
    case Booking.confirm_booking(socket.assigns.lead, params) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:lead, updated)
         |> assign(:step, :payment_pending)
         |> assign(:policy_required, false)
         |> assign(:slot_unavailable, false)}

      {:error, :policy_required} ->
        {:noreply, socket |> assign(:policy_required, true) |> assign(:slot_unavailable, false)}

      {:error, :slot_unavailable} ->
        {:noreply, socket |> assign(:slot_unavailable, true) |> assign(:policy_required, false)}

      # Defense in depth (issue 4e985412): the slot-selection form
      # itself now rejects a past date/time, but a slot picked as
      # "later today" can still go stale by the time the client
      # reaches this step — send them back to pick a new one rather
      # than leave them stuck retrying a confirmation that can never
      # succeed.
      {:error, :slot_in_past} ->
        {:noreply,
         socket
         |> assign(:step, :select_slot)
         |> assign(:slot_form, to_form(Booking.change_slot(socket.assigns.lead), as: :booking))
         |> assign(:policy_required, false)
         |> assign(:slot_unavailable, false)
         |> Phoenix.LiveView.put_flash(
           :error,
           "That time has already passed — please pick another slot."
         )}

      {:error, _reason} ->
        {:noreply, socket |> assign(:slot_unavailable, true) |> assign(:policy_required, false)}
    end
  end

  defp format_date(date), do: Calendar.strftime(date, "%B %-d, %Y")
  defp format_time(time), do: Calendar.strftime(time, "%-I:%M %p")
end
