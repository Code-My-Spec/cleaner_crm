defmodule CleanerCrmMcp.Tools.Scheduling.CreateAvailabilityBlock do
  use CleanerCrmMcp.Tool, name: "create_availability_block", mutates: true

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Block a cleaner's time off. MUTATES: adds a block that stops assignments in that window (existing jobs are not touched).
    Give all_day = true for a whole day, otherwise start_time and end_time. Returns the block {id, cleaner_id, date, all_day, start_time, end_time}.
    Errors when the cleaner is not in this account or a partial-day block lacks times.
    """

  @impl true
  def params,
    do: [
      %{name: "cleaner_id", type: :integer, required: true, description: "Cleaner id"},
      %{name: "date", type: :date, required: true, description: "YYYY-MM-DD"},
      %{
        name: "all_day",
        type: :boolean,
        required: false,
        description: "Whole day off (default false)"
      },
      %{
        name: "start_time",
        type: :time,
        required: false,
        description: "Partial-day start, HH:MM"
      },
      %{name: "end_time", type: :time, required: false, description: "Partial-day end, HH:MM"}
    ]

  @impl true
  def example,
    do:
      ~s|return create_availability_block({ cleaner_id = 7, date = "2026-11-12", all_day = true })|

  @impl true
  def call(args, scope) do
    with {:ok, cleaner} <- Shape.find_cleaner(scope, args["cleaner_id"]) do
      attrs =
        %{cleaner_id: cleaner.id, date: args["date"], all_day: args["all_day"] || false}
        |> then(
          &if args["start_time"], do: Map.put(&1, :start_time, args["start_time"]), else: &1
        )
        |> then(&if args["end_time"], do: Map.put(&1, :end_time, args["end_time"]), else: &1)

      with {:ok, block} <- Scheduling.create_availability_block(scope, attrs),
           do: {:ok, Shape.block(block)}
    end
  end
end
