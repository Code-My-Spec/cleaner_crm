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

  ## Card capture

  Real Stripe Elements card capture only exists once
  `:cleaner_crm, :stripe_publishable_key` is configured (prod only —
  see `config/runtime.exs`): the confirmation form omits its hidden
  `payment_method` field, `Booking.confirm_booking/3` creates an
  *unconfirmed* intent, and the `:card_capture` step mounts a Payment
  Element via the `.StripePaymentElement` colocated hook, which
  confirms the card client-side and pushes `"payment_confirmed"` or
  `"payment_failed"`. Dev/test never carry a publishable key, so they
  keep the previous hidden-test-card flow verbatim — every existing
  spex/LiveView test exercises that path unchanged.

  Either way, only the Stripe webhook
  (`CleanerCrm.Booking.receive_payment_webhook/1`) ever actually
  converts or declines the lead — this module never charges anything,
  it only ever asks Stripe to. The `.PaymentStatusPoll` hook polls
  `Booking.get_lead_by_token/1` every 3s while `@step ==
  :payment_pending` so the page updates live once the webhook lands,
  without requiring a manual refresh.

  ## Dependencies

  - `CleanerCrm.Booking`
  """

  use CleanerCrmWeb, :html

  require Logger

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
        |> assign(:stripe_publishable_key, stripe_publishable_key())
        |> assign(:stripe_client_secret, nil)
        |> assign(:card_error, nil)
        |> assign(:step, step_for(lead))
    end
  end

  # `nil` in dev/test (see `config/runtime.exs`) — the confirmation
  # form's fallback hidden `payment_method` field only renders when
  # this is `nil`, so keeping it unconfigured anywhere but prod is what
  # keeps every existing spex/LiveView test on the hidden-card path.
  defp stripe_publishable_key, do: Application.get_env(:cleaner_crm, :stripe_publishable_key)

  defp step_for(%Lead{status: :converted}), do: :confirmed
  defp step_for(%Lead{status: :payment_pending}), do: :payment_pending
  defp step_for(%Lead{status: :payment_declined}), do: :payment_declined
  defp step_for(%Lead{scheduled_date: nil}), do: :select_slot
  defp step_for(%Lead{}), do: :confirm

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} variant={:public}>
      <.header>Confirm your booking</.header>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".StripePaymentElement">
        export default {
          mounted() {
            const key = this.el.dataset.publishableKey
            const clientSecret = this.el.dataset.clientSecret
            const mountPoint = this.el.querySelector("[data-payment-element]")
            const submitButton = this.el.querySelector("[data-pay-button]")

            const boot = () => {
              this.stripe = window.Stripe(key)
              this.elements = this.stripe.elements({ clientSecret })
              this.paymentElement = this.elements.create("payment")
              this.paymentElement.mount(mountPoint)
            }

            if (window.Stripe) {
              boot()
            } else {
              const script = document.createElement("script")
              script.src = "https://js.stripe.com/v3/"
              script.onload = boot
              document.head.appendChild(script)
            }

            this.el.addEventListener("submit", async (event) => {
              event.preventDefault()
              if (!this.stripe || !this.elements) return

              submitButton?.setAttribute("disabled", "disabled")

              const { error } = await this.stripe.confirmPayment({
                elements: this.elements,
                redirect: "if_required",
              })

              if (error) {
                submitButton?.removeAttribute("disabled")
                this.pushEventTo(this.el, "payment_failed", { message: error.message })
              } else {
                this.pushEventTo(this.el, "payment_confirmed", {})
              }
            })
          },
        }
      </script>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".PaymentStatusPoll">
        export default {
          mounted() {
            this.timer = setInterval(() => {
              this.pushEventTo(this.el, "check_payment_status", {})
            }, 3000)
          },
          destroyed() {
            clearInterval(this.timer)
          },
        }
      </script>

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

      <div
        :if={@step == :payment_pending}
        id="payment-pending-poll"
        data-test="payment-pending"
        phx-hook=".PaymentStatusPoll"
        class="alert alert-info"
      >
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
            Real card capture (Stripe Elements, `:card_capture` step
            below) only exists once `@stripe_publishable_key` is
            configured — this hidden field mirrors the existing
            `/pay/:token` payment page's own simplification, a single
            test card baked in, everywhere that key isn't set (every
            dev/test environment, see `config/runtime.exs`).
          --%>
          <input
            :if={is_nil(@stripe_publishable_key)}
            type="hidden"
            name="booking[payment_method]"
            value="pm_card_visa"
          />

          <footer class="flex justify-end mt-4">
            <.button phx-disable-with="Booking...">
              {if @stripe_publishable_key,
                do: "Continue to payment",
                else: "Confirm & pay #{Money.format_cents(@lead.total_cents)}"}
            </.button>
          </footer>
        </.form>

        <form
          :if={@step == :card_capture}
          id="stripe-payment-form"
          data-test="stripe-payment-form"
          phx-hook=".StripePaymentElement"
          data-publishable-key={@stripe_publishable_key}
          data-client-secret={@stripe_client_secret}
        >
          <div data-payment-element data-test="stripe-payment-element" class="mb-4"></div>

          <p :if={@card_error} data-test="card-error" class="text-sm text-error mb-2">
            {@card_error}
          </p>

          <footer class="flex justify-end">
            <.button type="submit" data-pay-button="true" data-test="pay-button">
              Pay {Money.format_cents(@lead.total_cents)}
            </.button>
          </footer>
        </form>
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
      # Stripe Elements flow: the intent is unconfirmed — hand the
      # client_secret to the `.StripePaymentElement` hook and wait for
      # it to push back "payment_confirmed"/"payment_failed", rather
      # than moving straight to :payment_pending below.
      {:ok, %{lead: updated, client_secret: client_secret}} ->
        {:noreply,
         socket
         |> assign(:lead, updated)
         |> assign(:step, :card_capture)
         |> assign(:stripe_client_secret, client_secret)
         |> assign(:card_error, nil)
         |> assign(:policy_required, false)
         |> assign(:slot_unavailable, false)}

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

      # Anything else is a payment/system failure, NOT a slot conflict —
      # mislabeling it as "someone else booked this" sends the client
      # hunting for a new time that will fail identically.
      {:error, reason} ->
        Logger.error(
          "Booking confirmation failed for lead #{socket.assigns.lead.id}: " <>
            inspect(reason)
        )

        {:noreply,
         socket
         |> assign(:policy_required, false)
         |> assign(:slot_unavailable, false)
         |> Phoenix.LiveView.put_flash(
           :error,
           "We could not process your payment. Please try again, or contact us to finish booking."
         )}
    end
  end

  # Pushed by `.StripePaymentElement` once `stripe.confirmPayment/1`
  # resolves without an error.
  def handle_event("payment_confirmed", _params, socket) do
    {:noreply, socket |> assign(:step, :payment_pending) |> assign(:card_error, nil)}
  end

  # Pushed by `.StripePaymentElement` when `stripe.confirmPayment/1`
  # itself rejects the card — stays on :card_capture so the client can
  # retry.
  def handle_event("payment_failed", %{"message" => message}, socket) do
    {:noreply, assign(socket, :card_error, message)}
  end

  # Pushed every 3s by `.PaymentStatusPoll` while `@step ==
  # :payment_pending`, so the page advances the moment the Stripe
  # webhook (`CleanerCrm.Booking.receive_payment_webhook/1`) converts
  # or declines the lead — without requiring a manual refresh.
  def handle_event("check_payment_status", _params, socket) do
    case Booking.get_lead_by_token(socket.assigns.lead.acceptance_token) do
      %Lead{status: :converted} = refreshed ->
        {:noreply, socket |> assign(:lead, refreshed) |> assign(:step, :confirmed)}

      %Lead{status: :payment_declined} = refreshed ->
        {:noreply, socket |> assign(:lead, refreshed) |> assign(:step, :payment_declined)}

      _still_pending ->
        {:noreply, socket}
    end
  end

  defp format_date(date), do: Calendar.strftime(date, "%B %-d, %Y")
  defp format_time(time), do: Calendar.strftime(time, "%-I:%M %p")
end
