defmodule CleanerCrmWeb.FieldLive.EarningsComponent do
  @moduledoc """
  The cleaner's running pay-period earnings total alongside the
  account's drive-time policy, rendered on `CleanerCrmWeb.FieldLive.Today`.

  ## Assigns

  | Assign        | Type        | Required | Description       |
  |---------------|-------------|----------|--------------------|
  | id            | string      | yes      | LiveComponent DOM id |
  | current_scope | `Scope.t()` | yes      | caller scope         |

  ## Dependencies

  - `CleanerCrm.TimeTracking`
  """

  use CleanerCrmWeb, :live_component

  alias CleanerCrm.Money
  alias CleanerCrm.TimeTracking

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="card bg-base-100 border border-base-300 mb-3">
      <div class="card-body py-3">
        <div class="stat p-0">
          <div class="stat-title">This pay period</div>
          <div class="stat-value text-lg" data-test="pay-period-total">
            {Money.format_cents(@total_cents)}
          </div>
        </div>
        <p data-test="drive-time-policy" class="text-xs opacity-70">
          Drive time between jobs is {drive_time_label(@drive_time_policy)}.
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    scope = assigns.current_scope
    period = TimeTracking.current_pay_period(scope)
    totals = TimeTracking.cleaner_pay_totals(scope, period)
    time_tracked_cents = Map.get(totals, scope.user.id, 0)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:total_cents, time_tracked_cents + portal_tip_cents(scope, period))
     |> assign(:drive_time_policy, TimeTracking.drive_time_policy(scope))}
  end

  # `CleanerCrm.Portal` (story 852) may not exist yet, or may land
  # after this component does — read defensively
  # (`Code.ensure_loaded?/1` + `function_exported?/3`), mirroring
  # `FieldLive.Today`'s optional read of `CleanerCrm.Notifications`.
  # Expected contract: `tip_cents_for_cleaner/3` sums the cents a
  # cleaner has been tipped through the portal within the given pay
  # period.
  defp portal_tip_cents(scope, period) do
    if Code.ensure_loaded?(CleanerCrm.Portal) and
         function_exported?(CleanerCrm.Portal, :tip_cents_for_cleaner, 3) do
      CleanerCrm.Portal.tip_cents_for_cleaner(scope, scope.user.id, period)
    else
      0
    end
  end

  defp drive_time_label(:paid), do: "paid"
  defp drive_time_label(:unpaid), do: "unpaid"
end
