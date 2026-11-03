defmodule CleanerCrmMcp.Server do
  @moduledoc """
  The CRM's MCP server, mounted at `/mcp` (see `CleanerCrmWeb.Router`).

  Two tools only — `tool_docs` and `run_script`. Everything else is reached
  from a script; see `CleanerCrmMcp`.
  """

  use Anubis.Server,
    name: "cleaner-crm",
    version: "0.1.0",
    capabilities: [:tools]

  component(CleanerCrmMcp.Components.ToolDocs, name: "tool_docs")
  component(CleanerCrmMcp.Components.RunScript, name: "run_script")
end
