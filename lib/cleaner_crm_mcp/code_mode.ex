defmodule CleanerCrmMcp.CodeMode do
  @moduledoc """
  Runs an agent's Lua script against the CRM's tools, and documents them.

  CONTRACT (the MCP components depend on exactly this):

    * `eval(script, scope, opts \\\\ [])` → `%CleanerCrmMcp.CodeMode.Result{}`
      Runs `script` in a sandboxed Lua VM with every tool in
      `CleanerCrmMcp.Catalog.tools/0` bound as a global function taking one
      table. Never raises for anything the script did.
    * `render(result)` → `String.t()`: the text the MCP reply carries (value as
      JSON, printed lines, or the error), capped to `max_answer_bytes/0`.
    * `docs(opts)` → `String.t()`: with no options, the index (every tool and
      its one-line summary, grouped); `name: "x"` one tool's full page
      (description, parameters, example); `names: [...]` several pages;
      `search: "words"` ranked matches.

  Sandbox: `Lua.new/1` blocks io/os/file/require/load/dofile/package; on top of
  that an instruction budget, call depth, string size and a wall-clock timeout
  (the script runs in its own process, killed on timeout).
  """

  alias CleanerCrm.Users.Scope
  alias CleanerCrmMcp.Catalog
  alias CleanerCrmMcp.CodeMode.{Bindings, Docs, LuaValue, Result}

  @max_answer_bytes 24_000
  @default_timeout 30_000
  @limits [max_instructions: 10_000_000, max_call_depth: 200, max_string_bytes: 256 * 1024]

  @doc "The largest answer a reply carries, in bytes."
  def max_answer_bytes, do: @max_answer_bytes

  @doc """
  Runs `script` with the tools bound. Options: `tools:` (modules, default the
  catalog), `timeout:` (ms, default 30_000), and the limits `max_instructions`,
  `max_call_depth`, `max_string_bytes`.
  """
  @spec eval(String.t(), Scope.t(), keyword()) :: Result.t()
  def eval(script, %Scope{} = scope, opts \\ []) when is_binary(script) do
    tools = Keyword.get(opts, :tools) || Catalog.tools()
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    owner = self()
    tag = make_ref()

    {pid, mon} =
      spawn_monitor(fn ->
        Process.put(:code_mode_sink, {owner, tag})
        send(owner, {tag, :done, run(script, scope, tools, opts)})
      end)

    outcome =
      receive do
        {^tag, :done, result} ->
          Process.demonitor(mon, [:flush])
          result

        {:DOWN, ^mon, :process, ^pid, reason} ->
          # The result message, if any, was sent before exit and is already queued.
          receive do
            {^tag, :done, result} -> result
          after
            0 -> {:error, :crashed, "the script died: #{inspect(reason)}"}
          end
      after
        timeout ->
          Process.exit(pid, :kill)
          Process.demonitor(mon, [:flush])
          {:error, :timeout, "the script ran longer than #{timeout} ms and was stopped"}
      end

    finish(outcome, drain_prints(tag, []))
  end

  defp drain_prints(tag, acc) do
    receive do
      {^tag, :print, line} -> drain_prints(tag, [line | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp finish({:ok, value}, prints), do: %Result{value: value, prints: prints}

  defp finish({:error, kind, message}, prints),
    do: %Result{prints: prints, error: %{kind: kind, message: message}}

  defp run(script, scope, tools, opts) do
    lua =
      @limits
      |> Enum.map(fn {k, v} -> {k, Keyword.get(opts, k, v)} end)
      |> Lua.new()
      |> Bindings.install(tools, scope)

    {values, _lua} = Lua.eval!(lua, script)
    {:ok, values |> Enum.map(&LuaValue.from_lua/1) |> single()}
  rescue
    error in Lua.CompilerException ->
      {:error, :compile, Lua.format_exception(error)}

    error in Lua.RuntimeException ->
      message = Exception.message(error)

      case Bindings.failure() do
        {kind, text} when kind in [:rejected_call, :crashed] ->
          if message =~ text,
            do: {:error, kind, text <> hint(kind, text, tools)},
            else: runtime(message, tools)

        _ ->
          runtime(message, tools)
      end

    error ->
      {:error, :crashed, "the script died: " <> Exception.message(error)}
  end

  defp single([]), do: nil
  defp single([one]), do: one
  defp single(many), do: many

  defp runtime(message, tools), do: {:error, kind(message), explain(message, tools)}

  defp kind(message) do
    cond do
      message =~ "instruction budget exceeded" -> :instruction_budget
      message =~ "stack overflow" -> :call_depth
      message =~ "string too large" -> :result_too_large
      message =~ "is sandboxed" -> :sandboxed
      true -> :runtime
    end
  end

  defp hint(:rejected_call, text, _tools) do
    name = text |> String.split(":", parts: 2) |> hd()

    "\n\nThe script stopped here; the call did not run. " <>
      "`tool_docs({ name = \"#{name}\" })`, called directly, gives its parameters."
  end

  defp hint(:crashed, _text, _tools), do: "\n\nThe script stopped here."

  # A name bound nowhere gets the remedy and the likely names.
  defp explain(message, tools) do
    case Regex.run(~r/attempt to call a nil value \(global '([^']+)'\)/, message) do
      [_, name] -> message <> did_you_mean(name, tools)
      _ -> message
    end
  end

  defp did_you_mean(name, tools) do
    near =
      tools
      |> Enum.map(& &1.name())
      |> Enum.sort_by(&(-String.jaro_distance(&1, name)))
      |> Enum.filter(&(String.jaro_distance(&1, name) > 0.8))
      |> Enum.take(3)

    case near do
      [] ->
        "\n\nNo function is bound under that name. `tool_docs({ search = \"...\" })`, called " <>
          "directly rather than from a script, lists what exists. Only the CRM's functions are " <>
          "available (no io, os, require or other libraries)."

      names ->
        "\n\nNo function is bound under that name. Did you mean " <>
          Enum.map_join(names, " or ", &"`#{&1}`") <>
          "? `tool_docs({ name = \"#{hd(names)}\" })`, called directly, gives its parameters."
    end
  end

  @doc "The reply text for a result: value as JSON, then prints, or the error."
  @spec render(Result.t()) :: String.t()
  def render(%Result{error: nil, value: value, prints: prints}) do
    [encode(value) | prints] |> Enum.join("\n") |> cap()
  end

  def render(%Result{error: %{kind: kind, message: message}, prints: prints}) do
    printed = if prints == [], do: [], else: ["", "Printed before the error:" | prints]
    (["#{kind}: #{message}"] ++ printed) |> Enum.join("\n") |> cap()
  end

  defp encode(value) do
    case Jason.encode(value, pretty: true) do
      {:ok, json} -> json
      {:error, _} -> inspect(value, pretty: true, limit: :infinity)
    end
  end

  @doc "Cuts text to `max_answer_bytes/0` on a valid UTF-8 boundary, saying it did."
  def cap(text) when is_binary(text) do
    text = if String.valid?(text), do: text, else: scrub(text)

    if byte_size(text) <= @max_answer_bytes do
      text
    else
      note = "\n\n[truncated: the answer was longer than #{@max_answer_bytes} bytes]"

      text
      |> binary_part(0, @max_answer_bytes - byte_size(note))
      |> trim_to_valid_utf8()
      |> Kernel.<>(note)
    end
  end

  defp scrub(binary), do: to_valid(binary, <<>>)

  defp to_valid(<<>>, acc), do: acc

  defp to_valid(bin, acc) do
    case :unicode.characters_to_binary(bin, :utf8, :utf8) do
      ok when is_binary(ok) -> acc <> ok
      {:error, good, <<_, rest::binary>>} -> to_valid(rest, acc <> good <> "\uFFFD")
      {:error, good, <<>>} -> acc <> good
      {:incomplete, good, _} -> acc <> good <> "\uFFFD"
    end
  end

  defp trim_to_valid_utf8(<<>>), do: <<>>

  defp trim_to_valid_utf8(bin) do
    if String.valid?(bin),
      do: bin,
      else: trim_to_valid_utf8(binary_part(bin, 0, byte_size(bin) - 1))
  end

  @doc "Documentation: index, `name:`, `names:` or `search:`; `tools:` overrides the catalog."
  @spec docs(keyword() | map()) :: String.t()
  def docs(opts \\ []), do: Docs.render(opts)
end
