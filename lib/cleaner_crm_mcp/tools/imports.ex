defmodule CleanerCrmMcp.Tools.Imports do
  @moduledoc """
  Tool group: Imports: What came from other systems (Maidily): map source ids and job numbers to CRM records.

  Each tool is a module under `CleanerCrmMcp.Tools.Imports.*` implementing
  `CleanerCrmMcp.Tool`. List it in `tools/0` to make it callable from scripts.
  """

  @doc "Tool modules in this group, in documentation order."
  def tools,
    do: [
      CleanerCrmMcp.Tools.Imports.FindImported,
      CleanerCrmMcp.Tools.Imports.ListImports
    ]
end
