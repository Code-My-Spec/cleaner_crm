defmodule CleanerCrmWeb.QualityLive.Scorecards do
  @moduledoc """
  Per-cleaner quality trends: pick a cleaner to see their average
  quality score and how it's trending across completed jobs (see
  `CleanerCrm.Quality.Scorecard`).

  ## Routes

    * `/app/quality/scorecards` (`:index`)

  ## Dependencies

  - `CleanerCrm.Quality`
  - `CleanerCrm.Scheduling` (read-only: the account's cleaner roster)
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Quality
  alias CleanerCrm.Scheduling

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Scorecards
        <:subtitle>Per-cleaner quality trends</:subtitle>
        <:actions>
          <.button navigate={~p"/app/quality"} class="btn-sm btn-ghost">Back to Quality</.button>
        </:actions>
      </.header>

      <p :if={Enum.empty?(@cleaners)} class="text-center py-8 text-base-content/70">
        No cleaners yet.
      </p>

      <div class="flex flex-col md:flex-row gap-6">
        <ul :if={Enum.any?(@cleaners)} class="list md:w-64">
          <li :for={cleaner <- @cleaners} class="list-row">
            <button
              type="button"
              phx-click="select-cleaner"
              phx-value-id={cleaner.id}
              data-test={"scorecard-cleaner-#{cleaner.id}"}
              class="link text-left"
            >
              {cleaner.name || cleaner.email}
            </button>
          </li>
        </ul>

        <div :if={@scorecard} class="card bg-base-100 border border-base-300 flex-1">
          <div class="card-body space-y-2">
            <h3 class="font-semibold">{@selected_cleaner.name || @selected_cleaner.email}</h3>

            <p data-test="scorecard-average-score">
              Average score: {format_average(@scorecard.average)}
            </p>

            <p data-test="scorecard-trend">
              Trend: {@scorecard.trend}
            </p>

            <p class="text-sm text-base-content/70">Based on {@scorecard.count} completed job(s)</p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    cleaners = Scheduling.list_cleaners(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Scorecards")
     |> assign(:cleaners, cleaners)
     |> assign(:selected_cleaner, nil)
     |> assign(:scorecard, nil)}
  end

  @impl true
  def handle_event("select-cleaner", %{"id" => id}, socket) do
    cleaner_id = String.to_integer(id)
    cleaner = Enum.find(socket.assigns.cleaners, &(&1.id == cleaner_id))
    scorecard = Quality.cleaner_scorecard(socket.assigns.current_scope, cleaner_id)

    {:noreply,
     socket
     |> assign(:selected_cleaner, cleaner)
     |> assign(:scorecard, scorecard)}
  end

  defp format_average(nil), do: "—"
  defp format_average(average), do: :erlang.float_to_binary(average * 1.0, decimals: 1)
end
