defmodule CleanerCrmMcp.Tools.Clients.Shape do
  @moduledoc """
  Presenters shared by the Clients tools. Property presenters here NEVER
  include `lockbox_code` / `alarm_code`; only `access/1` does, and only
  `get_property_access` / `update_property_access` call it.
  """

  alias CleanerCrmMcp.Present

  @client_fields ~w(id name email phone preferred_channel active card_on_file inserted_at)a
  @property_fields ~w(id client_id service_address entry_method parking_notes pet_notes
                      client_preferences emergency_contact_name emergency_contact_phone)a
  @lead_fields ~w(id status client_name client_email client_phone pricing_model bedroom_count
                  bathroom_count square_feet hours frequency add_ons scheduled_date start_time
                  end_time client_id property_id job_id recurring_plan_id inserted_at)a

  @doc "A client, without properties."
  def client(client) do
    client |> Present.pick(@client_fields)
  end

  @doc "A property, with `has_lockbox_code`/`has_alarm_code` flags but never the codes."
  def property(property) do
    property
    |> Present.pick(@property_fields)
    |> Map.merge(%{
      "has_lockbox_code" => present?(property.lockbox_code),
      "has_alarm_code" => present?(property.alarm_code)
    })
  end

  @doc "The secret access codes of a property. Only for the access tools."
  def access(property) do
    %{
      "property_id" => property.id,
      "service_address" => property.service_address,
      "entry_method" => property.entry_method,
      "lockbox_code" => property.lockbox_code,
      "alarm_code" => property.alarm_code
    }
  end

  @doc "A lead with money as cents and dollars."
  def lead(lead) do
    lead
    |> Present.pick(@lead_fields)
    |> Map.merge(Present.money("total", lead.total_cents))
  end

  @doc "A compact job line for a client's recent/upcoming summaries."
  def job_line(job) do
    job
    |> Present.pick(~w(id job_number scheduled_date start_time end_time status property_id)a)
    |> Map.merge(Present.money("agreed_price", job.agreed_price_cents))
  end

  @doc "Maps a context error to something Present.error/1 renders well."
  def not_found(what), do: {:error, "#{what} not found"}

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(_), do: true
end
