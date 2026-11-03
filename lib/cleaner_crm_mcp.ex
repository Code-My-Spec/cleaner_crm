defmodule CleanerCrmMcp do
  @moduledoc """
  The CRM, for agents.

  An MCP server (`CleanerCrmMcp.Server`, mounted at `/mcp`) that advertises two
  tools:

    * `tool_docs` — what the CRM's functions are and what each takes.
    * `run_script` — runs a sandboxed Lua script with those functions bound,
      so an agent composes several reads and writes in one call.

  This is "code mode" (adapted from CodeMySpec's `CodeMode`). The functions a
  script can call are plain modules implementing `CleanerCrmMcp.Tool`, grouped
  by domain under `CleanerCrmMcp.Tools.*` and listed by `CleanerCrmMcp.Catalog`.
  Adding a function means adding a module to a group; nothing is advertised to
  the client individually, so the tool surface stays two tools wide.

  Every call runs with the caller's `CleanerCrm.Users.Scope` (resolved from an
  API token by `CleanerCrmWeb.McpAuth`), so a script has exactly the authority
  of the user the token belongs to, in that user's account.
  """

  use Boundary,
    deps: [CleanerCrm],
    exports: [Server, Catalog, CodeMode, Tool, Args, Present]
end
