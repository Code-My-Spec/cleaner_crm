defmodule CleanerCrmMcp.Tools.Scheduling do
  @moduledoc """
  Tool group: Scheduling: Jobs, job numbers, cleaners, assignments, recurring plans, availability.

  Each tool is a module under `CleanerCrmMcp.Tools.Scheduling.*` implementing
  `CleanerCrmMcp.Tool`. List it in `tools/0` to make it callable from scripts.
  """

  alias CleanerCrmMcp.Tools.Scheduling, as: S

  @doc "Tool modules in this group, in documentation order."
  def tools,
    do: [
      S.ListJobs,
      S.GetJob,
      S.ListUnassignedJobs,
      S.CreateJob,
      S.UpdateJob,
      S.AssignCleaner,
      S.UnassignCleaner,
      S.CancelJob,
      S.ListCleaners,
      S.GetCleaner,
      S.RegisterCleaner,
      S.CleanerSchedule,
      S.CheckSlot,
      S.ListRecurringPlans,
      S.GetRecurringPlan,
      S.CreateRecurringPlan,
      S.PreviewPlanConflicts,
      S.ListAvailabilityBlocks,
      S.CreateAvailabilityBlock
    ]
end
