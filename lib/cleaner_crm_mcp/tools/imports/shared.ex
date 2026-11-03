defmodule CleanerCrmMcp.Tools.Imports.Shared do
  @moduledoc false

  alias CleanerCrm.Imports.ImportRecord
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.Scope

  # Raw fields safe to echo back (no contact details).
  @summary_keys ~w(name status legacy_status scheduled_date start_time end_time
                   agreed_price_cents total_cents service_address recurrence flags)

  def present(%Scope{} = scope, %ImportRecord{} = record) do
    base = %{
      "kind" => record.kind,
      "source" => record.source,
      "source_id" => record.source_id,
      "source_ref" => record.source_ref,
      "crm_id" => record.target_id,
      "summary" => Map.take(record.raw || %{}, @summary_keys)
    }

    if record.kind == "job",
      do: Map.put(base, "job_number", job_number(scope, record.target_id)),
      else: base
  end

  defp job_number(scope, id) do
    Scheduling.get_job!(scope, id).job_number
  rescue
    _ -> nil
  end
end
