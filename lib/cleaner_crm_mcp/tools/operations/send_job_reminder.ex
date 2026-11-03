defmodule CleanerCrmMcp.Tools.Operations.SendJobReminder do
  use CleanerCrmMcp.Tool, name: "send_job_reminder", mutates: true

  alias CleanerCrm.Notifications
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    SENDS A REAL MESSAGE TO THE CUSTOMER: emails or texts the job's client an appointment reminder with confirm/reschedule links, right now.
    Only call this when explicitly asked to remind that customer; it cannot be undone and may duplicate the automatic reminder.
    Uses the client's preferred channel (SMS falls back to email) and logs a notification.
    Returns the logged notification. Errors when job_number matches no job, the job has no client, or the client has no email or phone to reach.
    """

  @impl true
  def params,
    do: [%{name: "job_number", type: :integer, required: true, description: "The job's number"}]

  @impl true
  def example, do: ~s|return send_job_reminder({ job_number = 1042 })|

  @impl true
  def call(%{"job_number" => number}, scope) do
    with {:ok, job} <- Shape.resolve_job(scope, number),
         {:ok, notification} <- Notifications.send_job_reminder(scope, job) do
      {:ok, Shape.notification(%{notification | client: job.client, cleaner: nil})}
    end
  end
end
