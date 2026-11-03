defmodule CleanerCrmMcp.Components.ToolDocs do
  @moduledoc """
  What functions `run_script` can call in the CRM, and what each one takes.

  Call with nothing for the index: every function and a one-line summary,
  grouped (clients, scheduling, quoting, billing, imports). Call with `name`
  for one function's arguments and a runnable example, `names` for several,
  or `search` when you know what you want to do but not what it is called.
  """

  use Anubis.Server.Component, type: :tool

  alias Anubis.Server.Response
  alias CleanerCrmMcp.CodeMode

  schema do
    field :name, :string, description: "A function name, for its full documentation"

    field :names, {:list, :string},
      description: "Several function names at once. Use instead of `name`, not with it"

    field :search, :string,
      description: "Search function names and descriptions. Ignored when a name is given"
  end

  @impl true
  def execute(params, frame) do
    case frame.assigns[:current_scope] do
      %{active_account_id: id} when not is_nil(id) ->
        opts =
          params
          |> Map.take([:name, :names, :search])
          |> Enum.reject(fn {_k, v} -> v in [nil, "", []] end)

        {:reply, Response.text(Response.tool(), CodeMode.docs(opts)), frame}

      _ ->
        {:reply, Response.error(Response.tool(), "not authenticated to an account"), frame}
    end
  end
end
