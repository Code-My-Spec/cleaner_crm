defmodule CleanerCrmWeb.QuoteLive.RateCard do
  @moduledoc """
  Owner-only management of the account's booking rate card (story 848):
  base per-room/per-sqft/hourly rates, recurring-frequency discounts,
  and named add-on prices — the same `CleanerCrm.Quoting.RateCard`
  fields the public instant-quote calculator
  (`CleanerCrmWeb.BookingLive.Quote`, at `/book`) reads. Before this
  page existed, an owner had no UI path to set them; only a direct
  database edit reached the frequency-discount and add-on fields (see
  `CleanerCrmWeb.QuoteLive.Builder`, which edits only the four base
  rates, in raw cents, alongside building a quote — left as-is since
  story 835's own spex drives that form).

  Base rates and add-on prices are entered in dollars and converted to
  cents before they ever reach the changeset — `RateCard` itself only
  stores integer cents — mirroring
  `CleanerCrmWeb.ScheduleLive.JobFormComponent`'s pay-rate inputs.
  Frequency discounts are plain percents, cast directly.

  `add_on_rates_cents` is a bare string-keyed map rather than an
  embedded schema, so it can't use `inputs_for`'s sort/drop
  convention. Its rows are tracked here as socket state
  (`@add_on_rows`, each with an id stable across edits so removing one
  row never renumbers another) and folded into the changeset's
  `add_on_rates_cents` attr on every change.

  ## Route

    * `/app/quotes/rate-card` (`:edit`) — office-only, gated the same as
      every other `/app/quotes` route.

  ## Dependencies

  - `CleanerCrm.Quoting`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Quoting
  alias CleanerCrm.Quoting.RateCard

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Booking Rate Card
        <:subtitle>Prices the public instant-quote calculator at <code>/book</code> uses</:subtitle>
        <:actions>
          <.button navigate={~p"/app/quotes"} class="btn-sm btn-ghost">Back to Quotes</.button>
        </:actions>
      </.header>

      <.form
        for={@form}
        id="rate-card-form"
        data-test="rate-card-form"
        phx-change="validate"
        phx-submit="save"
      >
        <div class="card bg-base-100 border border-base-300 mb-6">
          <div class="card-body">
            <h2 class="card-title">Base rates</h2>

            <.input
              type="number"
              step="0.01"
              min="0"
              name="rate_card[per_room_bedroom_rate]"
              id={@form[:per_room_bedroom_rate_cents].id}
              label="Per bedroom ($)"
              value={@rate_inputs.per_room_bedroom_rate}
              errors={field_errors(@form[:per_room_bedroom_rate_cents])}
              data-test="per-room-bedroom-rate-input"
            />
            <.input
              type="number"
              step="0.01"
              min="0"
              name="rate_card[per_room_bathroom_rate]"
              id={@form[:per_room_bathroom_rate_cents].id}
              label="Per bathroom ($)"
              value={@rate_inputs.per_room_bathroom_rate}
              errors={field_errors(@form[:per_room_bathroom_rate_cents])}
              data-test="per-room-bathroom-rate-input"
            />
            <.input
              type="number"
              step="0.01"
              min="0"
              name="rate_card[per_sqft_rate]"
              id={@form[:per_sqft_rate_cents].id}
              label="Per square foot ($)"
              value={@rate_inputs.per_sqft_rate}
              errors={field_errors(@form[:per_sqft_rate_cents])}
              data-test="per-sqft-rate-input"
            />
            <.input
              type="number"
              step="0.01"
              min="0"
              name="rate_card[hourly_rate]"
              id={@form[:hourly_rate_cents].id}
              label="Hourly ($)"
              value={@rate_inputs.hourly_rate}
              errors={field_errors(@form[:hourly_rate_cents])}
              data-test="hourly-rate-input"
            />
            <.input
              type="number"
              step="0.01"
              min="0"
              name="rate_card[minimum_visit_rate]"
              id={@form[:minimum_visit_cents].id}
              label="Minimum visit price ($)"
              value={@rate_inputs.minimum_visit_rate}
              errors={field_errors(@form[:minimum_visit_cents])}
              data-test="minimum-visit-rate-input"
            />
            <p class="text-sm text-base-content/70">
              The lowest total the instant-quote calculator will ever show. Leave blank for no floor.
            </p>
          </div>
        </div>

        <div class="card bg-base-100 border border-base-300 mb-6">
          <div class="card-body">
            <h2 class="card-title">Frequency discounts</h2>
            <p class="text-sm text-base-content/70">
              Percent off the one-time subtotal for a recurring booking. Leave blank for no discount.
            </p>

            <.input
              field={@form[:weekly_discount_percent]}
              type="number"
              min="0"
              max="100"
              label="Weekly (%)"
              data-test="weekly-discount-input"
            />
            <.input
              field={@form[:biweekly_discount_percent]}
              type="number"
              min="0"
              max="100"
              label="Bi-weekly (%)"
              data-test="biweekly-discount-input"
            />
            <.input
              field={@form[:monthly_discount_percent]}
              type="number"
              min="0"
              max="100"
              label="Monthly (%)"
              data-test="monthly-discount-input"
            />
          </div>
        </div>

        <div class="card bg-base-100 border border-base-300 mb-6">
          <div class="card-body">
            <h2 class="card-title">Add-ons</h2>
            <p class="text-sm text-base-content/70">
              Named extras a client can add to their instant quote (e.g. "Inside fridge").
            </p>

            <div
              :for={row <- @add_on_rows}
              class="flex items-end gap-2 mb-2"
              data-test={"add-on-row-#{row.id}"}
            >
              <.input
                type="text"
                name={"rate_card[add_ons][#{row.id}][name]"}
                id={"rate-card-add-on-#{row.id}-name"}
                label="Name"
                value={row.name}
                data-test={"add-on-name-input-#{row.id}"}
              />
              <.input
                type="number"
                step="0.01"
                min="0"
                name={"rate_card[add_ons][#{row.id}][dollars]"}
                id={"rate-card-add-on-#{row.id}-dollars"}
                label="Price ($)"
                value={row.dollars}
                data-test={"add-on-price-input-#{row.id}"}
              />
              <button
                type="button"
                class="btn btn-ghost btn-sm mb-2"
                phx-click="remove_add_on"
                phx-value-row_id={row.id}
                data-test={"remove-add-on-#{row.id}"}
              >
                Remove
              </button>
            </div>

            <p :for={msg <- field_errors(@form[:add_on_rates_cents])} class="text-sm text-error mb-2">
              {msg}
            </p>

            <button
              type="button"
              class="btn btn-sm"
              phx-click="add_add_on"
              data-test="add-add-on-button"
            >
              <.icon name="hero-plus" class="size-4 mr-1" /> Add add-on
            </button>
          </div>
        </div>

        <footer class="flex justify-end">
          <.button phx-disable-with="Saving..." variant="primary" data-test="save-rate-card-button">
            Save Rate Card
          </.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    rate_card = Quoting.get_or_create_rate_card(scope)

    {:ok,
     socket
     |> assign(:page_title, "Booking Rate Card")
     |> assign(:rate_card, rate_card)
     |> assign(:rate_inputs, rate_inputs(rate_card))
     |> assign(:add_on_rows, add_on_rows(rate_card))
     |> assign(:next_row_id, map_size(rate_card.add_on_rates_cents))
     |> assign(:form, to_form(Quoting.change_rate_card(scope, rate_card), as: :rate_card))}
  end

  @impl true
  def handle_event("validate", %{"rate_card" => params}, socket) do
    {:noreply, apply_params(socket, params, :validate)}
  end

  def handle_event("save", %{"rate_card" => params}, socket) do
    %{current_scope: scope, rate_card: rate_card} = socket.assigns
    {attrs, rate_inputs, add_on_rows} = build_attrs(socket, params)

    case Quoting.update_rate_card(scope, rate_card, attrs) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rate card updated.")
         |> assign(:rate_card, updated)
         |> assign(:rate_inputs, rate_inputs(updated))
         |> assign(:add_on_rows, add_on_rows(updated))
         |> assign(:next_row_id, map_size(updated.add_on_rates_cents))
         |> assign(:form, to_form(Quoting.change_rate_card(scope, updated), as: :rate_card))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:rate_inputs, rate_inputs)
         |> assign(:add_on_rows, add_on_rows)
         |> assign(:form, to_form(changeset, as: :rate_card))}
    end
  end

  def handle_event("add_add_on", _params, socket) do
    row = %{id: socket.assigns.next_row_id, name: "", dollars: ""}

    {:noreply,
     socket
     |> update(:add_on_rows, &(&1 ++ [row]))
     |> update(:next_row_id, &(&1 + 1))}
  end

  def handle_event("remove_add_on", %{"row_id" => row_id}, socket) do
    row_id = String.to_integer(row_id)

    {:noreply, update(socket, :add_on_rows, &Enum.reject(&1, fn row -> row.id == row_id end))}
  end

  defp apply_params(socket, params, action) do
    {attrs, rate_inputs, add_on_rows} = build_attrs(socket, params)

    changeset =
      socket.assigns.current_scope
      |> Quoting.change_rate_card(socket.assigns.rate_card, attrs)
      |> Map.put(:action, action)

    socket
    |> assign(:rate_inputs, rate_inputs)
    |> assign(:add_on_rows, add_on_rows)
    |> assign(:form, to_form(changeset, as: :rate_card))
  end

  # Builds the changeset attrs (dollar inputs converted to cents,
  # add-on rows folded into `add_on_rates_cents`) alongside the raw
  # dollar strings and add-on rows to redisplay — the same three
  # values both `validate` and `save` need, so both event handlers
  # (`apply_params/3` for the former, `save`'s own handler for the
  # latter) go through here.
  defp build_attrs(socket, params) do
    rate_inputs = %{
      per_room_bedroom_rate: Map.get(params, "per_room_bedroom_rate", ""),
      per_room_bathroom_rate: Map.get(params, "per_room_bathroom_rate", ""),
      per_sqft_rate: Map.get(params, "per_sqft_rate", ""),
      hourly_rate: Map.get(params, "hourly_rate", ""),
      minimum_visit_rate: Map.get(params, "minimum_visit_rate", "")
    }

    add_on_rows = sync_add_on_rows(socket.assigns.add_on_rows, Map.get(params, "add_ons", %{}))

    attrs = %{
      "per_room_bedroom_rate_cents" => dollars_to_cents(rate_inputs.per_room_bedroom_rate),
      "per_room_bathroom_rate_cents" => dollars_to_cents(rate_inputs.per_room_bathroom_rate),
      "per_sqft_rate_cents" => dollars_to_cents(rate_inputs.per_sqft_rate),
      "hourly_rate_cents" => dollars_to_cents(rate_inputs.hourly_rate),
      "minimum_visit_cents" => dollars_to_cents(rate_inputs.minimum_visit_rate),
      "weekly_discount_percent" => Map.get(params, "weekly_discount_percent"),
      "biweekly_discount_percent" => Map.get(params, "biweekly_discount_percent"),
      "monthly_discount_percent" => Map.get(params, "monthly_discount_percent"),
      "add_on_rates_cents" => add_on_rates_cents(add_on_rows)
    }

    {attrs, rate_inputs, add_on_rows}
  end

  defp sync_add_on_rows(rows, add_ons_params) do
    Enum.map(rows, fn row ->
      case Map.get(add_ons_params, to_string(row.id)) do
        %{"name" => name, "dollars" => dollars} -> %{row | name: name, dollars: dollars}
        _ -> row
      end
    end)
  end

  # Only named rows are persisted — a row added but never given a
  # name is a placeholder, not "priced at $0". A named row with an
  # unparseable or blank price becomes `nil` cents, which
  # `RateCard.changeset/2` rejects with a validation error rather than
  # silently treating it as free.
  defp add_on_rates_cents(rows) do
    rows
    |> Enum.filter(fn row -> String.trim(row.name || "") != "" end)
    |> Map.new(fn row -> {String.trim(row.name), dollars_to_cents(row.dollars)} end)
  end

  defp rate_inputs(%RateCard{} = rate_card) do
    %{
      per_room_bedroom_rate: cents_to_dollars(rate_card.per_room_bedroom_rate_cents),
      per_room_bathroom_rate: cents_to_dollars(rate_card.per_room_bathroom_rate_cents),
      per_sqft_rate: cents_to_dollars(rate_card.per_sqft_rate_cents),
      hourly_rate: cents_to_dollars(rate_card.hourly_rate_cents),
      minimum_visit_rate: cents_to_dollars(rate_card.minimum_visit_cents)
    }
  end

  defp add_on_rows(%RateCard{add_on_rates_cents: rates}) do
    rates
    |> Enum.sort_by(fn {name, _cents} -> name end)
    |> Enum.with_index()
    |> Enum.map(fn {{name, cents}, index} ->
      %{id: index, name: name, dollars: cents_to_dollars(cents)}
    end)
  end

  defp cents_to_dollars(nil), do: ""

  defp cents_to_dollars(cents),
    do: cents |> Decimal.new() |> Decimal.div(Decimal.new(100)) |> Decimal.to_string(:normal)

  # An unparseable dollar amount (or a blank input) becomes `nil`
  # rather than raising — base rates are optional at the schema level
  # (a `nil` rate means "not priced yet", see `RateCard`'s moduledoc),
  # so an invalid entry is left for `validate_number`/
  # `validate_add_on_rates` to reject rather than crashing the form.
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
