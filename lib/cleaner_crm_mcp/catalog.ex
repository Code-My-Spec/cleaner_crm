defmodule CleanerCrmMcp.Catalog do
  @moduledoc """
  Every function a `run_script` script may call, gathered from the tool groups,
  and argument validation/coercion against each tool's declared `params/0`.

  Groups are modules with a `tools/0` returning tool modules. Add a group here;
  add tools to a group.
  """

  alias CleanerCrmMcp.Tools

  @groups [
    Tools.Clients,
    Tools.Scheduling,
    Tools.Quoting,
    Tools.Billing,
    Tools.Operations,
    Tools.Imports
  ]

  @doc "The tool groups, in documentation order."
  def groups, do: @groups

  @doc "Every tool module."
  def tools, do: Enum.flat_map(@groups, & &1.tools())

  @doc "The tool module with this name."
  def fetch(name) when is_binary(name) do
    case Enum.find(tools(), &(&1.name() == name)) do
      nil -> :error
      tool -> {:ok, tool}
    end
  end

  @doc """
  Validates `args` (a map with string keys, as decoded from a Lua table) against
  `tool.params/0` and coerces each value to its declared type.

  Returns `{:ok, coerced}` or `{:error, message}` naming every problem.
  Unknown keys are an error (they are usually misspellings).
  """
  def coerce(tool, args) when is_map(args) do
    params = tool.params()
    known = MapSet.new(params, & &1.name)

    unknown =
      args |> Map.keys() |> Enum.map(&to_string/1) |> Enum.reject(&MapSet.member?(known, &1))

    {coerced, problems} =
      Enum.reduce(params, {%{}, []}, fn %{name: name} = param, {acc, problems} ->
        case fetch_arg(args, name) do
          :missing ->
            if param[:required],
              do: {acc, ["`#{name}` is required" | problems]},
              else: {acc, problems}

          {:ok, nil} ->
            if param[:required],
              do: {acc, ["`#{name}` is required" | problems]},
              else: {acc, problems}

          {:ok, value} ->
            case cast(param.type, value) do
              {:ok, cast} -> {Map.put(acc, name, cast), problems}
              :error -> {acc, ["`#{name}` must be #{describe(param.type)}" | problems]}
            end
        end
      end)

    problems =
      Enum.reverse(problems) ++
        Enum.map(unknown, fn key ->
          "unknown argument `#{key}` (takes: #{Enum.map_join(params, ", ", & &1.name)})"
        end)

    case problems do
      [] -> {:ok, coerced}
      _ -> {:error, Enum.join(problems, "; ")}
    end
  end

  defp fetch_arg(args, name) do
    case Map.fetch(args, name) do
      {:ok, v} -> {:ok, v}
      :error -> :missing
    end
  end

  defp cast(:string, v) when is_binary(v), do: {:ok, v}
  defp cast(:string, v) when is_number(v), do: {:ok, to_string(v)}
  defp cast(:integer, v) when is_integer(v), do: {:ok, v}
  defp cast(:integer, v) when is_float(v) and trunc(v) == v, do: {:ok, trunc(v)}

  defp cast(:integer, v) when is_binary(v) do
    case Integer.parse(String.trim_leading(v, "#")) do
      {i, ""} -> {:ok, i}
      _ -> :error
    end
  end

  defp cast(:number, v) when is_number(v), do: {:ok, v}

  defp cast(:number, v) when is_binary(v) do
    case Float.parse(v) do
      {f, ""} -> {:ok, f}
      _ -> :error
    end
  end

  defp cast(:boolean, v) when is_boolean(v), do: {:ok, v}
  defp cast(:date, %Date{} = d), do: {:ok, d}

  defp cast(:date, v) when is_binary(v) do
    case Date.from_iso8601(v) do
      {:ok, d} -> {:ok, d}
      _ -> :error
    end
  end

  defp cast(:time, %Time{} = t), do: {:ok, t}

  defp cast(:time, v) when is_binary(v) do
    v =
      if Regex.match?(~r/^\d{1,2}:\d{2}$/, v), do: String.pad_leading(v, 5, "0") <> ":00", else: v

    case Time.from_iso8601(v) do
      {:ok, t} -> {:ok, t}
      _ -> :error
    end
  end

  defp cast(:list, v) when is_list(v), do: {:ok, v}
  # Lua has no arrays: a table with keys 1..n arrives as a map; accept it as a list.
  defp cast(:list, v) when is_map(v) do
    keys = Map.keys(v)

    if keys != [] and Enum.all?(keys, &is_integer/1) do
      {:ok, keys |> Enum.sort() |> Enum.map(&Map.fetch!(v, &1))}
    else
      if keys == [], do: {:ok, []}, else: :error
    end
  end

  defp cast(:map, v) when is_map(v), do: {:ok, v}
  defp cast(_type, _v), do: :error

  defp describe(:date), do: "a date \"YYYY-MM-DD\""
  defp describe(:time), do: "a time \"HH:MM\" or \"HH:MM:SS\""
  defp describe(:integer), do: "an integer"
  defp describe(:number), do: "a number"
  defp describe(:boolean), do: "true or false"
  defp describe(:string), do: "a string"
  defp describe(:list), do: "a list"
  defp describe(:map), do: "a table"
end
