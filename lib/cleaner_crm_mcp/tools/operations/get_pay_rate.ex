defmodule CleanerCrmMcp.Tools.Operations.GetPayRate do
  use CleanerCrmMcp.Tool, name: "get_pay_rate"

  alias CleanerCrm.TimeTracking
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    Get a cleaner's default pay rate.
    Returns { cleaner_id, basis ("hourly" or "piece_rate"), rate, rate_cents }, or nil when no rate has been set.
    Errors when cleaner_id is not a member of this account. A job's own pay settings override this default.
    """

  @impl true
  def params,
    do: [
      %{name: "cleaner_id", type: :integer, required: true, description: "The cleaner's user id"}
    ]

  @impl true
  def example, do: ~s|return get_pay_rate({ cleaner_id = 12 })|

  @impl true
  def call(%{"cleaner_id" => cleaner_id}, scope) do
    with :ok <- Shape.ensure_cleaner(scope, cleaner_id) do
      {:ok, scope |> TimeTracking.get_pay_rate(cleaner_id) |> Shape.pay_rate()}
    end
  end
end
