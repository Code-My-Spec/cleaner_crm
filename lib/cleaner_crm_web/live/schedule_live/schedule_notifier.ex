defmodule CleanerCrmWeb.ScheduleLive.ScheduleNotifier do
  @moduledoc """
  Composes the cleaner-facing schedule-change alert (story 843) shared
  by every path that can reschedule, reassign, or cancel a job from the
  board: `ScheduleLive.Index`'s inline time/cleaner controls and cancel
  button, and `ScheduleLive.JobFormComponent`'s "Edit Job" dialog.

  This is the sanctioned place for it, not `CleanerCrm.Scheduling`: the
  dependency graph has `Notifications -> Scheduling`, so `Scheduling`
  itself must never call back into `Notifications` — callers under
  `schedule_live/` are what's allowed to depend on both and compose
  them.
  """

  alias CleanerCrm.Scheduling

  @doc """
  Creates a pending schedule-change notification for `job`'s assigned
  cleaner. No-ops for an unassigned job (nobody to notify) or if
  `CleanerCrm.Notifications` isn't loaded yet.
  """
  def notify_schedule_change(scope, job, change_summary) do
    if job.cleaner_id && notifications_ready?(:create_notification, 2) do
      cleaner = Enum.find(Scheduling.list_cleaners(scope), &(&1.id == job.cleaner_id))

      CleanerCrm.Notifications.create_notification(scope, %{
        cleaner_id: job.cleaner_id,
        job_id: job.id,
        kind: :schedule_change,
        channel: notification_channel(cleaner),
        status: :pending,
        change_summary: change_summary,
        pushed_at: DateTime.utc_now(),
        token: "schedule_change_#{job.id}_#{System.unique_integer([:positive])}"
      })
    end
  end

  # Falls back to SMS when the cleaner has push notifications
  # disabled. There's no such preference on `CleanerCrm.Users.User`
  # yet, so this is currently always `:push` — matched defensively so
  # it starts honoring the preference the moment that field lands,
  # with no further change needed here.
  defp notification_channel(%{push_enabled: false}), do: :sms
  defp notification_channel(_cleaner), do: :push

  @doc """
  Whether `CleanerCrm.Notifications` exports `fun/arity` — read
  defensively (`function_exported?` rather than a direct call) so
  callers tolerate that context landing or changing shape
  independently of the schedule board.
  """
  def notifications_ready?(fun, arity),
    do:
      Code.ensure_loaded?(CleanerCrm.Notifications) and
        function_exported?(CleanerCrm.Notifications, fun, arity)

  def format_time_12h(%Time{} = time) do
    {hour, period} = to_12_hour(time.hour)
    "#{hour}:#{time.minute |> Integer.to_string() |> String.pad_leading(2, "0")} #{period}"
  end

  defp to_12_hour(0), do: {12, "AM"}
  defp to_12_hour(hour) when hour < 12, do: {hour, "AM"}
  defp to_12_hour(12), do: {12, "PM"}
  defp to_12_hour(hour), do: {hour - 12, "PM"}
end
