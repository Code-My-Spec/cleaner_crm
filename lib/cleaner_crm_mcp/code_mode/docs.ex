defmodule CleanerCrmMcp.CodeMode.Docs do
  @moduledoc """
  Tool documentation rendered on demand from each tool's own declarations:
  an index (grouped), one tool's page, several pages, or ranked search.
  """

  alias CleanerCrmMcp.{Catalog, Tool}

  @lua_reserved ~w(and break do else elseif end false for function goto if in local nil not
                   or repeat return then true until while)

  def render(opts \\ []) do
    opts = Map.new(opts)
    tools = Map.get(opts, :tools) || Catalog.tools()

    cond do
      is_binary(opts[:name]) ->
        page(tools, opts[:name])

      is_list(opts[:names]) and opts[:names] != [] ->
        Enum.map_join(opts[:names], "\n\n---\n\n", &page(tools, to_string(&1)))

      is_binary(opts[:search]) and String.trim(opts[:search]) != "" ->
        search(tools, opts[:search])

      true ->
        index(tools)
    end
  end

  defp index(tools) do
    grouped = grouped(tools)

    body =
      Enum.map_join(grouped, "\n\n", fn {heading, group_tools} ->
        lines = Enum.map_join(group_tools, "\n", &"  #{&1.name()} - #{Tool.summary(&1)}")
        "## #{heading}\n#{lines}"
      end)

    """
    #{length(tools)} functions are callable from a script. Call them by name with one table:
    `local job = get_job({ job_number = 1042 })`

    A function that cannot answer returns nil and an error table:
    `local job, err = get_job({ job_number = 99999 })` (err.message says why).
    Ask for one by name to see its arguments: tool_docs({ name = "get_job" }).

    #{body}
    """
    |> String.trim_trailing()
  end

  defp grouped(tools) do
    groups =
      for group <- Catalog.groups(),
          members = group_tools(group),
          in_group = Enum.filter(tools, &(&1 in members)),
          in_group != [] do
        {heading(group), in_group}
      end

    listed = groups |> Enum.flat_map(&elem(&1, 1))

    case Enum.reject(tools, &(&1 in listed)) do
      [] -> groups
      rest -> groups ++ [{"Other", rest}]
    end
  end

  defp group_tools(group) do
    if Code.ensure_loaded?(group) and function_exported?(group, :tools, 0),
      do: group.tools(),
      else: []
  rescue
    _ -> []
  end

  defp heading(module) do
    with {:docs_v1, _, _, _, %{"en" => doc}, _, _} <- Code.fetch_docs(module),
         line when line != "" <- doc |> String.split("\n", parts: 2) |> hd() |> String.trim() do
      String.trim_trailing(line, ".")
    else
      _ -> module |> Module.split() |> List.last()
    end
  end

  defp page(tools, name) do
    case Enum.find(tools, &(&1.name() == name)) do
      nil -> not_found(tools, name)
      tool -> full(tool)
    end
  end

  defp full(tool) do
    changes = if tool.mutates?(), do: "\n**Changes data.**\n", else: ""
    example = String.trim(tool.example())

    example =
      if example == "",
        do: "local result, err = #{tool.name()}(#{skeleton(tool)})",
        else: example

    """
    # #{tool.name()}
    #{changes}
    #{String.trim(tool.description())}

    ## Parameters

    #{params_table(tool)}#{reserved_note(tool)}

    ## Example

    ```lua
    #{example}
    ```
    """
    |> String.trim_trailing()
  end

  defp params_table(tool) do
    case tool.params() do
      [] ->
        "None (call with no arguments or `{}`)."

      params ->
        rows =
          Enum.map(params, fn p ->
            "| #{p.name} | #{p.type} | #{if p[:required], do: "yes", else: "no"} | #{String.replace(p.description, "|", "\\|")} |"
          end)

        Enum.join(["| name | type | required | description |", "|---|---|---|---|" | rows], "\n")
    end
  end

  defp reserved_note(tool) do
    case tool.params() |> Enum.map(& &1.name) |> Enum.filter(&(&1 in @lua_reserved)) do
      [] ->
        ""

      words ->
        "\n\nLua reserved words (#{Enum.join(words, ", ")}) cannot be table fields; write `{ [\"#{hd(words)}\"] = ... }`."
    end
  end

  defp skeleton(tool) do
    case Enum.filter(tool.params(), & &1[:required]) do
      [] ->
        "{}"

      req ->
        "{ " <> Enum.map_join(req, ", ", &"#{key(&1.name)} = #{placeholder(&1.type)}") <> " }"
    end
  end

  defp key(name), do: if(name in @lua_reserved, do: ~s(["#{name}"]), else: name)
  defp placeholder(t) when t in [:integer, :number], do: "1"
  defp placeholder(:boolean), do: "true"
  defp placeholder(t) when t in [:list, :map], do: "{}"
  defp placeholder(_), do: ~s("...")

  defp search(tools, term) do
    words = term |> String.downcase() |> String.split(~r/[^\p{L}\p{N}_]+/u, trim: true)

    ranked =
      tools
      |> Enum.map(fn tool -> {score(tool, words), tool} end)
      |> Enum.filter(fn {s, _} -> s > 0 end)
      |> Enum.sort_by(fn {s, t} -> {-s, t.name()} end)

    case ranked do
      [] ->
        "Nothing matches #{inspect(term)}. #{length(tools)} functions are available; call tool_docs with no arguments for the index."

      _ ->
        lines = Enum.map_join(ranked, "\n", fn {_, t} -> "  #{t.name()} - #{Tool.summary(t)}" end)

        "#{length(ranked)} match #{inspect(term)}. Ask for one by name to see its arguments.\n\n#{lines}"
    end
  end

  defp score(tool, words) do
    name = String.downcase(tool.name())
    desc = String.downcase(tool.description())

    Enum.sum(
      for w <- words do
        cond do
          name == w -> 10
          String.contains?(name, w) -> 5
          String.contains?(desc, w) -> 1
          true -> 0
        end
      end
    )
  end

  defp not_found(tools, name), do: not_found_message(tools, name)

  @doc false
  def not_found_message(tools, name) do
    near =
      tools
      |> Enum.map(& &1.name())
      |> Enum.filter(
        &(String.jaro_distance(&1, name) > 0.8 or String.contains?(&1, name) or
            String.contains?(name, &1))
      )
      |> Enum.sort_by(&(-String.jaro_distance(&1, name)))
      |> Enum.take(5)

    case near do
      [] ->
        "No function called #{inspect(name)}. Call tool_docs with no arguments for the index, or { search = \"...\" }."

      names ->
        "No function called #{inspect(name)}. Did you mean: #{Enum.join(names, ", ")}?"
    end
  end
end
