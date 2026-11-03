defmodule CleanerCrmMcp.Tools.Billing.GetCancellationPolicy do
  use CleanerCrmMcp.Tool, name: "get_cancellation_policy"

  alias CleanerCrm.Portal
  alias CleanerCrmMcp.Tools.Billing.Shape

  @impl true
  def description,
    do: """
    Get the account's client cancellation policy.
    Returns notice_window_hours, late_fee and same_day_fee ({x_cents, x}) and policy_text. An account that never set one returns zero fees and the default 24-hour window.
    """

  @impl true
  def example, do: ~s|return get_cancellation_policy().late_fee|

  @impl true
  def call(_args, scope),
    do: {:ok, scope.active_account_id |> Portal.get_cancellation_policy() |> Shape.policy()}
end
