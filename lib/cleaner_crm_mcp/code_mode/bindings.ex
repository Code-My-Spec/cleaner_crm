defmodule CleanerCrmMcp.CodeMode.Bindings do
  @moduledoc """
  Binds tools into a Lua VM as global functions and captures `print`.

      local job, err = get_job({ job_number = 1042 })

  One table in; the value out. A tool failure returns `nil, {tool, message,
  details}`. A malformed call (failed `Catalog.coerce/2`) or a crashing tool
  raises, stopping the script; the reason is recorded in the process dictionary
  (`failure/0`) so the runner can report its kind faithfully.
  """

  require Logger

  alias CleanerCrm.Users.Scope
  alias CleanerCrmMcp.{Catalog, Present}
  alias CleanerCrmMcp.CodeMode.LuaValue

  @failure :code_mode_failure

  @doc "Binds `print` and every tool in `tools`, acting for `scope`."
  def install(lua, tools, %Scope{} = scope) do
    lua = Lua.set!(lua, [:print], &print/2)

    Enum.reduce(tools, lua, fn tool, acc ->
      Lua.set!(acc, [String.to_atom(tool.name())], callback(tool, scope))
    end)
  end

  @doc "`{kind, message}` recorded by a call that stopped the script, or nil."
  def failure, do: Process.get(@failure)

  # Prints are sent to the evaluating caller so they survive a kill or timeout.
  defp print(args, state) do
    line = Enum.map_join(args, "\t", &render/1)

    case Process.get(:code_mode_sink) do
      {pid, tag} -> send(pid, {tag, :print, line})
      _ -> :ok
    end

    {[], state}
  end

  defp render(v) when is_binary(v), do: v
  defp render(nil), do: "nil"
  defp render(v) when is_boolean(v), do: to_string(v)
  defp render(v) when is_float(v), do: v |> LuaValue.from_lua() |> to_string()
  defp render(v) when is_number(v), do: to_string(v)
  defp render(v), do: inspect(v)

  defp callback(tool, scope) do
    fn args, state ->
      case Catalog.coerce(tool, arguments(state, args)) do
        {:error, message} ->
          stop(:rejected_call, "#{tool.name()}: #{message}")

        {:ok, coerced} ->
          case invoke(tool, coerced, scope) do
            {:ok, value} ->
              {encoded, state} = Lua.encode!(state, LuaValue.to_lua(value))
              {[encoded], state}

            {:error, reason} ->
              {encoded, state} = Lua.encode!(state, error_table(tool, reason))
              {[nil, encoded], state}
          end
      end
    end
  end

  defp error_table(tool, reason) do
    plain = Present.error(reason)

    base = %{"tool" => tool.name(), "message" => message(plain)}

    case reason do
      %Ecto.Changeset{} -> Map.put(base, "details", LuaValue.to_lua(plain))
      _ -> base
    end
  end

  defp message(text) when is_binary(text), do: text

  defp message(errors) when is_map(errors) do
    errors
    |> flatten_errors("")
    |> Enum.join("; ")
  end

  defp message(other), do: inspect(other)

  defp flatten_errors(errors, prefix) do
    Enum.flat_map(errors, fn
      {field, msgs} when is_list(msgs) ->
        Enum.flat_map(msgs, fn
          m when is_binary(m) -> ["#{prefix}#{field} #{m}"]
          m when is_map(m) -> flatten_errors(m, "#{prefix}#{field}.")
        end)

      {field, nested} when is_map(nested) ->
        flatten_errors(nested, "#{prefix}#{field}.")
    end)
  end

  defp arguments(_state, []), do: %{}

  defp arguments(state, [table | _]) do
    case state |> Lua.decode!(table) |> LuaValue.from_lua() do
      %{} = args -> args
      [] -> %{}
      other -> %{"_" => other}
    end
  end

  defp invoke(tool, args, scope) do
    tool.call(args, scope)
  rescue
    exception ->
      Logger.error(
        "[CodeMode] #{tool.name()} crashed: " <>
          Exception.format(:error, exception, __STACKTRACE__)
      )

      stop(:crashed, "#{tool.name()} crashed: #{Exception.message(exception)}")
  end

  defp stop(kind, message) do
    Process.put(@failure, {kind, message})
    raise Lua.RuntimeException, message
  end
end
