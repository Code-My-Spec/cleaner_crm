defmodule CleanerCrmWeb.QuoteLive.Index do
  @moduledoc """
  Lists the account's quotes with their status.

  ## Dependencies

  - `CleanerCrm.Quoting`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Quoting

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Quotes
        <:subtitle>Price and send quotes from your rate card</:subtitle>
        <:actions>
          <.button navigate={~p"/app/quotes/rate-card"} class="btn-sm btn-ghost">
            Rate Card
          </.button>
          <.button navigate={~p"/app/settings/booking"} class="btn-sm btn-ghost">
            Cancellation Policy
          </.button>
          <.button navigate={~p"/app/quotes/new"} variant="primary">
            <.icon name="hero-plus" class="size-4 mr-1" /> New Quote
          </.button>
        </:actions>
      </.header>

      <p :if={Enum.empty?(@quotes)} class="text-center py-12 text-base-content/70">
        No quotes yet.
      </p>

      <.table :if={Enum.any?(@quotes)} id="quotes" rows={@quotes}>
        <:col :let={quote} label="Client">{quote.client_name || "Unnamed lead"}</:col>
        <:col :let={quote} label="Pricing model">{pricing_model_label(quote.pricing_model)}</:col>
        <:col :let={quote} label="Total">{CleanerCrm.Money.format_cents(quote.total_cents)}</:col>
        <:col :let={quote} label="Status">
          <span class="badge" data-test="quote-status">{status_label(quote.status)}</span>
        </:col>
        <:action :let={quote}>
          <.link navigate={~p"/app/quotes/#{quote}"} class="btn btn-sm btn-ghost">View</.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :quotes, Quoting.list_quotes(socket.assigns.current_scope))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Quotes")}
  end

  defp pricing_model_label(:per_room), do: "Per room"
  defp pricing_model_label(:per_sqft), do: "Per square foot"
  defp pricing_model_label(:hourly), do: "Hourly"
  defp pricing_model_label(nil), do: "—"

  defp status_label(:draft), do: "Draft"
  defp status_label(:sent), do: "Sent"
end
