defmodule CleanerCrmWeb.QuoteLive.Builder do
  @moduledoc """
  Builds and sends a quote, with live totals as the owner fills it in.

  The rate card and quote forms live on the same page: a quote is
  priced by exactly one model at a time, so switching models drops
  whatever the previous model's inputs held (see
  `CleanerCrm.Quoting.Pricing.fields_for_model/1`). A quote is only
  ever persisted at the moment it's sent — before that, everything
  here is in-memory socket state.

  ## Routes

    * `/app/quotes/new` (`:new`) — build and send a new quote.
    * `/app/quotes/:id` (`:show`) — a previously sent quote, frozen against
      later rate-card changes.

  ## Dependencies

  - `CleanerCrm.Quoting`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Money
  alias CleanerCrm.Quoting
  alias CleanerCrm.Quoting.{Pricing, Quote}

  @impl true
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@quote.client_name || "Unnamed lead"}
        <:subtitle>{pricing_model_label(@quote.pricing_model)} quote</:subtitle>
        <:actions>
          <.button navigate={~p"/app/quotes"} class="btn-sm btn-ghost">Back to Quotes</.button>
        </:actions>
      </.header>

      <div class="card bg-base-100 border border-base-300">
        <div class="card-body space-y-4">
          <p>
            <span class="text-base-content/70">Status:</span>
            <span class="badge badge-success" data-test="quote-status">
              {status_label(@quote.status)}
            </span>
          </p>

          <p :if={@quote.client_phone}>
            <span class="text-base-content/70">Phone:</span> {@quote.client_phone}
          </p>

          <ul class="list">
            <li :for={item <- @quote.quote_items} class="list-row">
              <div class="list-col-grow">
                {item.description} × {item.quantity} @ {Money.format_cents(item.rate_cents)}
              </div>
              <div class="font-semibold">{Money.format_cents(item.amount_cents)}</div>
            </li>
          </ul>

          <p class="text-lg font-semibold">
            Total: <span data-test="quote-total">{Money.format_cents(@quote.total_cents)}</span>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        New Quote
        <:subtitle>Price a job by room, square footage, or hours</:subtitle>
      </.header>

      <div class="grid gap-6 lg:grid-cols-2">
        <div class="card bg-base-100 border border-base-300">
          <div class="card-body">
            <h2 class="card-title">Rate Card</h2>

            <.form
              for={@rate_card_form}
              id="rate-card-form"
              data-test="rate-card-form"
              phx-submit="save_rate_card"
            >
              <.input
                field={@rate_card_form[:per_room_bedroom_rate_cents]}
                type="number"
                label="Per-bedroom rate (cents)"
              />
              <.input
                field={@rate_card_form[:per_room_bathroom_rate_cents]}
                type="number"
                label="Per-bathroom rate (cents)"
              />
              <.input
                field={@rate_card_form[:per_sqft_rate_cents]}
                type="number"
                label="Per-square-foot rate (cents)"
              />
              <.input
                field={@rate_card_form[:hourly_rate_cents]}
                type="number"
                label="Hourly rate (cents)"
              />

              <footer>
                <.button phx-disable-with="Saving...">Save Rate Card</.button>
              </footer>
            </.form>
          </div>
        </div>

        <div class="card bg-base-100 border border-base-300">
          <div class="card-body">
            <h2 class="card-title">Quote Details</h2>

            <.form
              for={@form}
              id="quote-form"
              data-test="quote-form"
              phx-change="validate"
              phx-submit="validate"
            >
              <.input field={@form[:client_name]} type="text" label="Client name" />
              <.input field={@form[:client_phone]} type="text" label="Client phone" />

              <.input
                field={@form[:pricing_model]}
                type="select"
                label="Pricing model"
                prompt="Select a pricing model"
                options={[
                  {"Per room", :per_room},
                  {"Per square foot", :per_sqft},
                  {"Hourly", :hourly}
                ]}
              />

              <%!--
                Every model's inputs stay mounted at all times (never
                added or removed from the DOM) so a single form change
                can set a pricing model and its own field together in
                one round trip. Only the visible model's group loses
                the `hidden` class, and only its inputs carry a
                `data-test` attribute — the other models' fields are
                inert without either.
              --%>
              <div class={@pricing_model != :per_room && "hidden"}>
                <.input
                  field={@form[:bedroom_count]}
                  type="number"
                  label="Bedrooms"
                  data-test={active_field(@pricing_model, :per_room, "room-bedroom-count-input")}
                />
                <.input
                  field={@form[:bathroom_count]}
                  type="number"
                  label="Bathrooms"
                  data-test={active_field(@pricing_model, :per_room, "room-bathroom-count-input")}
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
            </.form>

            <p class="text-lg font-semibold mt-4">
              Total: <span data-test="quote-total">{Money.format_cents(@total_cents)}</span>
            </p>

            <p :if={@missing_rate?} data-test="missing-rate-warning" class="text-sm text-error">
              Add a rate for this pricing model on your rate card before sending this quote.
            </p>

            <footer class="flex justify-end mt-4">
              <.button
                type="button"
                phx-click="send_quote"
                data-test="send-quote-button"
                variant="primary"
              >
                Send Quote
              </.button>
            </footer>
          </div>
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
    scope = socket.assigns.current_scope
    rate_card = Quoting.get_or_create_rate_card(scope)
    changeset = Quoting.change_quote(scope, %Quote{})

    socket
    |> assign(:page_title, "New Quote")
    |> assign(:rate_card, rate_card)
    |> assign(:rate_card_form, to_form(Quoting.change_rate_card(scope, rate_card)))
    |> recalculate(changeset)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    quote = Quoting.get_quote!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, quote.client_name || "Quote")
    |> assign(:quote, quote)
  end

  @impl true
  def handle_event("validate", %{"quote" => quote_params}, socket) do
    changeset =
      socket.assigns.current_scope
      |> Quoting.change_quote(%Quote{}, sanitize_quote_params(quote_params))
      |> Map.put(:action, :validate)

    {:noreply, recalculate(socket, changeset)}
  end

  def handle_event("save_rate_card", %{"rate_card" => rate_card_params}, socket) do
    %{current_scope: scope, rate_card: rate_card, form: form} = socket.assigns

    case Quoting.update_rate_card(scope, rate_card, rate_card_params) do
      {:ok, rate_card} ->
        {:noreply,
         socket
         |> assign(:rate_card, rate_card)
         |> assign(:rate_card_form, to_form(Quoting.change_rate_card(scope, rate_card)))
         |> recalculate(form.source)}

      {:error, changeset} ->
        {:noreply, assign(socket, :rate_card_form, to_form(changeset))}
    end
  end

  def handle_event("send_quote", _params, socket) do
    %{current_scope: scope, quote_draft: draft, rate_card: rate_card} = socket.assigns

    case Quoting.send_quote(scope, draft, rate_card) do
      {:ok, quote} -> {:noreply, push_patch(socket, to: ~p"/app/quotes/#{quote}")}
      {:error, :not_finalizable} -> {:noreply, socket}
    end
  end

  defp recalculate(socket, %Ecto.Changeset{} = changeset) do
    quote_draft = Ecto.Changeset.apply_changes(changeset)
    line_items = Pricing.line_items(socket.assigns.rate_card, quote_draft)

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:quote_draft, quote_draft)
    |> assign(:pricing_model, quote_draft.pricing_model)
    |> assign(:total_cents, Pricing.total_cents(line_items))
    |> assign(:missing_rate?, Pricing.missing_rate?(line_items))
  end

  # The `data-test` attribute for a model-specific input: present only
  # while its model is the one currently selected, `nil` (i.e. omitted
  # entirely) otherwise — the input itself always stays in the DOM.
  defp active_field(pricing_model, pricing_model, data_test), do: data_test
  defp active_field(_pricing_model, _owning_model, _data_test), do: nil

  defp sanitize_quote_params(%{"pricing_model" => model} = params) do
    Map.take(params, [
      "client_name",
      "client_phone",
      "pricing_model" | Pricing.fields_for_model(model)
    ])
  end

  defp sanitize_quote_params(params),
    do: Map.take(params, ~w(client_name client_phone pricing_model))

  defp pricing_model_label(:per_room), do: "Per room"
  defp pricing_model_label(:per_sqft), do: "Per square foot"
  defp pricing_model_label(:hourly), do: "Hourly"
  defp pricing_model_label(nil), do: "Unpriced"

  defp status_label(:draft), do: "Draft"
  defp status_label(:sent), do: "Sent"
end
