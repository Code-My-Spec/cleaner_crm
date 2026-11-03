defmodule CleanerCrmMcp.Tools.Operations do
  @moduledoc """
  Tool group: Operations: time tracking and payroll, quality (checklists, incidents, scorecards), reviews, notifications and reminders, and the audit trail.

  Each tool is a module under `CleanerCrmMcp.Tools.Operations.*` implementing
  `CleanerCrmMcp.Tool`. List it in `tools/0` to make it callable from scripts.
  """

  alias CleanerCrmMcp.Tools.Operations

  @doc "Tool modules in this group, in documentation order."
  def tools do
    [
      Operations.ListTimeEntries,
      Operations.PayrollSummary,
      Operations.GetPayRate,
      Operations.SetPayRate,
      Operations.ListChecklistTemplates,
      Operations.GetJobChecklist,
      Operations.ListIncidents,
      Operations.GetScorecard,
      Operations.ListReviews,
      Operations.ReviewSummary,
      Operations.GetReminderSettings,
      Operations.UpdateReminderSettings,
      Operations.ListNotifications,
      Operations.SendJobReminder,
      Operations.ListAuditEntries
    ]
  end
end
