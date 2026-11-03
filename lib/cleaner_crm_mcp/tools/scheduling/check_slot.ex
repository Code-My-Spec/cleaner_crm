defmodule CleanerCrmMcp.Tools.Scheduling.CheckSlot do
  use CleanerCrmMcp.Tool, name: "check_slot"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    Check whether a date/time window is free of other (non-cancelled) jobs, regardless of cleaner.
    Returns {available, conflicting_jobs} where conflicting_jobs are shaped like list_jobs. Errors when end_time is not after start_time.
    """

  @impl true
  def params,
    do: [
      %{name: "date", type: :date, required: true, description: "YYYY-MM-DD"},
      %{name: "start_time", type: :time, required: true, description: "HH:MM"},
      %{name: "end_time", type: :time, required: true, description: "HH:MM"}
    ]

  @impl true
  def example,
    do:
      ~s|local r = check_slot({ date = "2026-11-10", start_time = "09:00", end_time = "11:00" })\nreturn r.available|

  @impl true
  def call(args, scope) do
    {date, s, e} = {args["date"], args["start_time"], args["end_time"]}

    if Time.compare(s, e) != :lt do
      {:error, "end_time must be after start_time"}
    else
      conflicts =
        scope
        |> Scheduling.search_jobs(%{from: date, to: date, limit: 200})
        |> Enum.filter(
          &(Time.compare(&1.start_time, e) == :lt and Time.compare(s, &1.end_time) == :lt)
        )
        |> Enum.map(&Shape.job/1)

      {:ok,
       %{
         "available" => Scheduling.slot_available?(scope, date, s, e),
         "conflicting_jobs" => conflicts
       }}
    end
  end
end
