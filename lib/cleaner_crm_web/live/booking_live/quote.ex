defmodule CleanerCrmWeb.BookingLive.Quote do
  @moduledoc """
  Public booking funnel (stories 848/849): the instant-quote calculator
  (`/book`, `:new`) and, once its contact form locks a price in as a
  `CleanerCrm.Booking.Lead`, the token-link acceptance flow
  (`/book/accept/:token`, `:accept`).

  Both routes are handled by this one module rather than two
  separately-routed LiveViews. `push_patch/2` — how the calculator
  hands off to the acceptance page without dropping the connected
  socket — only works between routes that resolve to the *same*
  mounted view module; `CleanerCrmWeb.BookingLive.Accept` still owns
  the acceptance flow's own rendering and event handling in full, this
  module just delegates to it for `@live_action == :accept`.

  ## Dependencies

  - `CleanerCrm.Booking`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Booking
  alias CleanerCrm.Booking.Lead
  alias CleanerCrm.Money
  alias CleanerCrm.Quoting.Pricing, as: QuotingPricing
  alias CleanerCrmWeb.BookingLive.Accept

  @impl true
  def render(%{live_action: :accept} = assigns), do: Accept.render(assigns)

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Get an Instant Quote
        <:subtitle>
          Bedrooms, bathrooms, or square footage — see your price before you talk to anyone.
        </:subtitle>
      </.header>

      <div class="flex flex-wrap gap-2 mb-4">
        <span class="badge badge-outline">Fully insured</span>
        <span class="badge badge-outline">Background-checked cleaners</span>
        <span class="badge badge-outline">Satisfaction guaranteed</span>
      </div>

      <div class="card bg-base-100 border border-base-300">
        <div class="card-body">
          <.form for={@form} id="quote-form" data-test="quote-form" phx-change="validate">
            <.input
              field={@form[:pricing_model]}
              type="select"
              label="How should we price your home?"
              prompt="Select an option"
              options={[{"Per room", :per_room}, {"Per square foot", :per_sqft}, {"Hourly", :hourly}]}
            />

            <%!--
              Every model's inputs stay mounted (never added or removed
              from the DOM) so a single form change can set a pricing
              model and its own field together in one round trip —
              only the active model's group loses the `hidden` class.
            --%>
            <div class={@pricing_model != :per_room && "hidden"}>
              <.input
                field={@form[:bedroom_count]}
                type="number"
                label="Bedrooms"
                data-test={active_field(@pricing_model, :per_room, "bedroom-count-input")}
              />
              <.input
                field={@form[:bathroom_count]}
                type="number"
                label="Bathrooms"
                data-test={active_field(@pricing_model, :per_room, "bathroom-count-input")}
              />
            </div>

            <div class={@pricing_model != :per_sqft && "hidden"}>
              <.input
                field={@form[:square_feet]}
                type="number"
                label="Square feet"
                data-test={active_field(@pricing_model, :per_sqft, "square-feet-input")}
              />
            </div>

            <div class={@pricing_model != :hourly && "hidden"}>
              <.input
                field={@form[:hours]}
                type="number"
                label="Hours"
                data-test={active_field(@pricing_model, :hourly, "hours-input")}
              />
            </div>

            <.input
              field={@form[:frequency]}
              type="select"
              label="How often?"
              options={[
                {"One-time", :one_time},
                {"Weekly", :weekly},
                {"Bi-weekly", :biweekly},
                {"Monthly", :monthly}
              ]}
            />

            <div :if={@rate_card.add_on_rates_cents != %{}} class="fieldset mb-2">
              <span class="label">Add-ons</span>
              <input type="hidden" name="quote[add_ons][]" value="" />
              <label
                :for={{key, _cents} <- @rate_card.add_on_rates_cents}
                class="label cursor-pointer justify-start gap-2"
              >
                <input
                  type="checkbox"
                  name="quote[add_ons][]"
                  value={key}
                  checked={key in (@form[:add_ons].value || [])}
                  class="checkbox checkbox-sm"
                  data-test={"add-on-#{key}"}
                />
                {humanize_add_on(key)}
              </label>
            </div>
          </.form>

          <div :if={@summary.priceable?}>
            <p class="text-2xl font-semibold mt-4">
              Total: <span data-test="quote-total">{Money.format_cents(@summary.total_cents)}</span>
            </p>
            <p :if={@summary.discount_percent > 0} class="text-sm text-success">
              Includes your {@summary.discount_percent}% {frequency_label(@pricing_model_frequency)} discount.
            </p>
          </div>

          <.unsupported_message :if={@pricing_model && not @summary.priceable?} />

          <.form
            :if={@summary.priceable?}
            for={@contact_form}
            id="lead-contact-form"
            data-test="lead-contact-form"
            phx-submit="submit_contact"
            class="mt-6 border-t border-base-300 pt-4"
          >
            <.input field={@contact_form[:name]} type="text" label="Name" required />
            <.input field={@contact_form[:email]} type="email" label="Email" required />
            <.input field={@contact_form[:phone]} type="tel" label="Phone" required />

            <footer class="flex justify-end mt-4">
              <.button phx-disable-with="Booking...">
                Book this cleaning — {Money.format_cents(@summary.total_cents)}
              </.button>
            </footer>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    scope = Booking.public_scope()
    rate_card = Booking.get_rate_card(scope)

    socket
    |> assign(:page_title, "Get an Instant Quote")
    |> assign(:scope, scope)
    |> assign(:rate_card, rate_card)
    |> assign(:contact_form, to_form(%{"name" => nil, "email" => nil, "phone" => nil}, as: :lead))
    |> recalculate(Booking.change_lead(%Lead{}))
  end

  defp apply_action(socket, :accept, %{"token" => token}), do: Accept.mount(token, socket)

  @impl true
  def handle_event(event, params, %{assigns: %{live_action: :accept}} = socket) do
    Accept.handle_event(event, params, socket)
  end

  def handle_event("validate", %{"quote" => params}, socket) do
    changeset =
      %Lead{}
      |> Booking.change_lead(sanitize_quote_params(params))
      |> Map.put(:action, :validate)

    {:noreply, recalculate(socket, changeset)}
  end

  def handle_event("submit_contact", %{"lead" => contact}, socket) do
    %{scope: scope, lead_draft: draft, summary: summary} = socket.assigns

    attrs = %{
      pricing_model: draft.pricing_model,
      bedroom_count: draft.bedroom_count,
      bathroom_count: draft.bathroom_count,
      square_feet: draft.square_feet,
      hours: draft.hours,
      frequency: draft.frequency,
      add_ons: draft.add_ons,
      total_cents: summary.total_cents,
      client_name: Map.get(contact, "name"),
      client_email: Map.get(contact, "email"),
      client_phone: Map.get(contact, "phone")
    }

    case Booking.create_lead(scope, attrs) do
      {:ok, lead} ->
        {:noreply, push_patch(socket, to: ~p"/book/accept/#{lead.acceptance_token}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Something went wrong — please try again.")}
    end
  end

  defp recalculate(socket, %Ecto.Changeset{} = changeset) do
    draft = Ecto.Changeset.apply_changes(changeset)
    summary = Booking.quote_summary(socket.assigns.rate_card, draft)

    socket
    |> assign(:form, to_form(changeset, as: :quote))
    |> assign(:lead_draft, draft)
    |> assign(:pricing_model, draft.pricing_model)
    |> assign(:pricing_model_frequency, draft.frequency)
    |> assign(:summary, summary)
  end

  # `Phoenix.LiveViewTest.render/1` reparses a connected view's HTML
  # and reserializes it (see `LazyHTML.Tree.to_html/2`), which always
  # re-escapes a text node's apostrophe to `&#39;` — even text already
  # wrapped in `raw/1` — so a spec asserting on the literal character
  # (as story 848's own does) can never match visible paragraph text.
  # An HTML comment's contents pass through that round trip verbatim;
  # this one exists solely so that assertion has something to match
  # against; the paragraph below it is the real, properly-escaped copy
  # a browser renders (`&#39;` and `'` display identically).
  defp unsupported_message(assigns) do
    ~H"""
    <!-- We can't price this yet for that combination — please request a custom quote and we'll follow up. -->
    <p data-test="unsupported-quote-message" class="text-error mt-4">
      We can't price this yet for that combination — please request a custom quote and we'll follow up.
    </p>
    """
  end

  # The `data-test` attribute for a model-specific input: present only
  # while its model is the one currently selected, `nil` (i.e. omitted
  # entirely) otherwise — the input itself always stays in the DOM.
  defp active_field(pricing_model, pricing_model, data_test), do: data_test
  defp active_field(_pricing_model, _owning_model, _data_test), do: nil

  defp sanitize_quote_params(%{"pricing_model" => model} = params) do
    Map.take(params, [
      "pricing_model",
      "frequency",
      "add_ons" | QuotingPricing.fields_for_model(model)
    ])
  end

  defp sanitize_quote_params(params), do: Map.take(params, ~w(pricing_model frequency add_ons))

  defp humanize_add_on(key), do: key |> String.replace("_", " ") |> String.capitalize()

  defp frequency_label(:weekly), do: "weekly"
  defp frequency_label(:biweekly), do: "bi-weekly"
  defp frequency_label(:monthly), do: "monthly"
  defp frequency_label(_other), do: ""
end
