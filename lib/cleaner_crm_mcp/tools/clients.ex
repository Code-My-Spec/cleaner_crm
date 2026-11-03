defmodule CleanerCrmMcp.Tools.Clients do
  @moduledoc """
  Tool group: Clients: Clients, properties, and booking leads.

  Each tool is a module under `CleanerCrmMcp.Tools.Clients.*` implementing
  `CleanerCrmMcp.Tool`. List it in `tools/0` to make it callable from scripts.
  """

  alias CleanerCrmMcp.Tools.Clients

  @doc "Tool modules in this group, in documentation order."
  def tools do
    [
      Clients.SearchClients,
      Clients.GetClient,
      Clients.CreateClient,
      Clients.UpdateClient,
      Clients.DeactivateClient,
      Clients.ListProperties,
      Clients.GetProperty,
      Clients.CreateProperty,
      Clients.UpdateProperty,
      Clients.GetPropertyAccess,
      Clients.UpdatePropertyAccess,
      Clients.ListLeads,
      Clients.GetLead
    ]
  end
end
