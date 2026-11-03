defmodule CleanerCrmMcp.CodeMode.LuaValue do
  @moduledoc """
  Lua tables <-> plain Elixir data, in both directions of a call.

  A decoded Lua table is a list of `{key, value}` pairs in hash order. Keys
  `1..n` make a list; anything else a map with string keys. Whole floats become
  integers (Lua has one number type).
  """

  @doc "A decoded Lua value as plain Elixir data."
  def from_lua([{_key, _value} | _] = table) do
    keys = Enum.map(table, &elem(&1, 0))

    if Enum.sort(keys) == Enum.to_list(1..length(keys)//1) do
      table |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(&from_lua(elem(&1, 1)))
    else
      Map.new(table, fn {key, value} -> {to_string(key), from_lua(value)} end)
    end
  end

  def from_lua(value) when is_float(value) do
    if trunc(value) == value, do: trunc(value), else: value
  end

  def from_lua(value), do: value

  @doc "Plain Elixir data made safe to hand to `Lua.encode!/2`."
  def to_lua(nil), do: nil
  def to_lua(v) when is_boolean(v) or is_number(v) or is_binary(v), do: v
  def to_lua(v) when is_atom(v), do: Atom.to_string(v)
  def to_lua(%Date{} = v), do: Date.to_iso8601(v)
  def to_lua(%Time{} = v), do: Time.to_iso8601(v)
  def to_lua(%DateTime{} = v), do: DateTime.to_iso8601(v)
  def to_lua(%NaiveDateTime{} = v), do: NaiveDateTime.to_iso8601(v)
  def to_lua(%Decimal{} = v), do: Decimal.to_float(v)
  def to_lua(%_{} = v), do: v |> CleanerCrmMcp.Present.plain() |> to_lua()
  def to_lua(v) when is_map(v), do: Map.new(v, fn {k, val} -> {to_key(k), to_lua(val)} end)
  def to_lua(v) when is_list(v), do: Enum.map(v, &to_lua/1)
  def to_lua(v) when is_tuple(v), do: v |> Tuple.to_list() |> to_lua()
  def to_lua(v), do: inspect(v)

  defp to_key(k) when is_binary(k) or is_integer(k), do: k
  defp to_key(k), do: to_string(k)
end
