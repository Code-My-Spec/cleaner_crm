defmodule CleanerCrmMcp.Tools.Scheduling.ListAvailabilityBlocks do
  use CleanerCrmMcp.Tool, name: "list_availability_blocks"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    List a cleaner's time-off blocks, soonest first.
    Returns [{id, cleaner_id, date, all_day, start_time, end_time}]. Errors when the cleaner is not in this account.
    """

  @impl true
  def params,
    do: [
      %{name: "cleaner_id", type: :integer, required: true, description: "Cleaner id"},
      %{name: "from", type: :date, required: false, description: "Earliest date"},
      %{name: "to", type: :date, required: false, description: "Latest date, inclusive"}
    ]

  @impl true
  def example, do: ~s|return list_availability_blocks({ cleaner_id = 7, from = "2026-11-01" })|

  @impl true
  def call(args, scope) do
    with {:ok, cleaner} <- Shape.find_cleaner(scope, args["cleaner_id"]) do
      {:ok,
       scope
       |> Scheduling.list_availability_blocks_between(cleaner.id, args["from"], args["to"])
       |> Enum.map(&Shape.block/1)}
    end
  end
end
