defmodule CleanerCrmMcp.Tools.Operations.UpdateReminderSettings do
  use CleanerCrmMcp.Tool, name: "update_reminder_settings", mutates: true

  alias CleanerCrm.Notifications

  @impl true
  def description,
    do: """
    Set how many hours before a job clients get their automatic appointment reminder.
    Saving also turns automatic reminders on for the account, which then email/text its clients.
    Returns { lead_time_hours, enabled }. Errors when lead_time_hours is not a positive integer.
    """

  @impl true
  def params,
    do: [
      %{
        name: "lead_time_hours",
        type: :integer,
        required: true,
        description: "Hours before the job, e.g. 24"
      }
    ]

  @impl true
  def example, do: ~s|return update_reminder_settings({ lead_time_hours = 48 })|

  @impl true
  def call(%{"lead_time_hours" => hours}, scope) do
    with {:ok, s} <- Notifications.update_reminder_settings(scope, %{lead_time_hours: hours}) do
      {:ok, %{"lead_time_hours" => s.lead_time_hours, "enabled" => true}}
    end
  end
end
