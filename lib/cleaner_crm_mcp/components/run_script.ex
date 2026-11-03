defmodule CleanerCrmMcp.Components.RunScript do
  @moduledoc """
  Run a Lua script against the CRM. Use it to do several steps in one call.

  Every CRM function is a global taking one table:

      local jobs = list_jobs({ from = "2026-11-03", to = "2026-11-09" })
      for _, job in ipairs(jobs) do
        if job.cleaner == nil then print("unassigned: #" .. job.job_number) end
      end
      return #jobs

  A function that ran but could not answer returns nil and an error table:

      local job, err = get_job({ job_number = 99999 })
      if job == nil then return "missing: " .. err.message end

  A malformed call (wrong type, missing required argument, unknown argument)
  stops the script with an error naming the problem.

  Call `tool_docs` for what each function takes. Scripts are sandboxed: no
  filesystem, network or OS, and limits on run time, recursion and result size.
  Functions that change data say so in their docs; they act with your account's
  authority.
  """

  use Anubis.Server.Component, type: :tool

  alias Anubis.Server.Response
  alias CleanerCrmMcp.CodeMode
  alias CleanerCrmMcp.CodeMode.Result

  schema do
    field :script, :string,
      required: true,
      description: "Lua source. Return a value to get it back; use print() for progress."
  end

  @impl true
  def execute(%{script: script}, frame) do
    case frame.assigns[:current_scope] do
      %{active_account_id: id} = scope when not is_nil(id) ->
        result = CodeMode.eval(script, scope)
        text = CodeMode.render(result)

        response =
          if Result.ok?(result),
            do: Response.text(Response.tool(), text),
            else: Response.error(Response.tool(), text)

        {:reply, response, frame}

      _ ->
        {:reply, Response.error(Response.tool(), "not authenticated to an account"), frame}
    end
  end
end
