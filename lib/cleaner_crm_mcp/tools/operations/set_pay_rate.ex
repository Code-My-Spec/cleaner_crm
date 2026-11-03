defmodule CleanerCrmMcp.Tools.Operations.SetPayRate do
  use CleanerCrmMcp.Tool, name: "set_pay_rate", mutates: true

  alias CleanerCrm.TimeTracking
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    Set (create or replace) a cleaner's default pay rate. Changes payroll defaults for future jobs.
    basis is "hourly" or "piece_rate"; rate is in dollars (hourly: per hour, piece_rate: per job).
    Returns the saved { cleaner_id, basis, rate, rate_cents }.
    Errors when cleaner_id is not in this account, basis is not valid, or rate is not positive.
    """

  @impl true
  def params,
    do: [
      %{name: "cleaner_id", type: :integer, required: true, description: "The cleaner's user id"},
      %{
        name: "basis",
        type: :string,
        required: true,
        description: "\"hourly\" or \"piece_rate\""
      },
      %{name: "rate", type: :number, required: true, description: "Dollars, e.g. 22.5"}
    ]

  @impl true
  def example, do: ~s|return set_pay_rate({ cleaner_id = 12, basis = "hourly", rate = 22.5 })|

  @impl true
  def call(%{"cleaner_id" => cleaner_id, "basis" => basis, "rate" => rate}, scope) do
    with :ok <- Shape.ensure_cleaner(scope, cleaner_id),
         {:ok, rate_cents} <- cents(rate),
         {:ok, saved} <-
           TimeTracking.set_pay_rate(scope, cleaner_id, %{basis: basis, rate_cents: rate_cents}) do
      {:ok, Shape.pay_rate(saved)}
    end
  end

  defp cents(rate) when rate > 0, do: {:ok, Args.to_cents(rate)}
  defp cents(_), do: {:error, "`rate` must be greater than 0"}
end
