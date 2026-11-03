defmodule CleanerCrmMcp.Tools.Operations.GetReminderSettings do
  use CleanerCrmMcp.Tool, name: "get_reminder_settings"

  alias CleanerCrm.Notifications

  @impl true
  def description,
    do: """
    Get the account's appointment reminder settings.
    Returns { lead_time_hours, enabled }: how many hours before a job the client is reminded automatically.
    enabled is false until settings have been saved once (automatic reminders only run for accounts that saved settings).
    """

  @impl true
  def example, do: ~s|return get_reminder_settings().lead_time_hours|

  @impl true
  def call(_args, scope) do
    s = Notifications.get_reminder_settings(scope)
    {:ok, %{"lead_time_hours" => s.lead_time_hours, "enabled" => not is_nil(s.id)}}
  end
end
