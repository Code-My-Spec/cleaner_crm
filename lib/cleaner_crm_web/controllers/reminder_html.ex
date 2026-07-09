defmodule CleanerCrmWeb.ReminderHTML do
  @moduledoc """
  Pages rendered by `CleanerCrmWeb.ReminderController` — the plain
  confirmation/reschedule pages a client lands on after tapping a link
  in their reminder.
  """

  use CleanerCrmWeb, :html

  embed_templates "reminder_html/*"
end
