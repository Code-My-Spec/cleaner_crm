defmodule CleanerCrmMcp.Present do
  @moduledoc """
  Turns domain structs into plain, script-friendly values: maps with string
  keys, ISO-8601 dates/times, atoms as strings, money as cents AND dollars.
  Tools return these, never structs.

  Prefer the specific presenters (`client/1`, `job/1`, ...) or `pick/2` with an
  explicit field list over `plain/1`, so answers stay small and stable.
  """

  @doc "Selected fields of a struct or map, each made plain. Missing fields are omitted."
  def pick(nil, _fields), do: nil

  def pick(struct_or_map, fields) when is_list(fields) do
    map = if is_struct(struct_or_map), do: Map.from_struct(struct_or_map), else: struct_or_map

    for field <- fields, Map.has_key?(map, field), loaded?(Map.get(map, field)), into: %{} do
      {to_string(field), plain(Map.get(map, field))}
    end
  end

  @doc "Any term made plain (structs become maps without Ecto metadata or unloaded associations)."
  def plain(nil), do: nil
  def plain(value) when is_boolean(value), do: value
  def plain(value) when is_atom(value), do: Atom.to_string(value)
  def plain(%Date{} = d), do: Date.to_iso8601(d)
  def plain(%Time{} = t), do: t |> Time.truncate(:second) |> Time.to_iso8601()
  def plain(%DateTime{} = dt), do: dt |> DateTime.truncate(:second) |> DateTime.to_iso8601()

  def plain(%NaiveDateTime{} = dt),
    do: dt |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601()

  def plain(%Decimal{} = d), do: Decimal.to_float(d)
  def plain(%Ecto.Association.NotLoaded{}), do: nil

  def plain(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.reject(fn {_k, v} -> match?(%Ecto.Association.NotLoaded{}, v) end)
    |> Map.new(fn {k, v} -> {to_string(k), plain(v)} end)
  end

  def plain(map) when is_map(map), do: Map.new(map, fn {k, v} -> {to_string(k), plain(v)} end)
  def plain(list) when is_list(list), do: Enum.map(list, &plain/1)
  def plain(tuple) when is_tuple(tuple), do: tuple |> Tuple.to_list() |> plain()
  def plain(other), do: other

  @doc "Integer cents as `%{\"<key>_cents\" => c, \"<key>\" => dollars}` (merge into a presented map)."
  def money(key, nil), do: %{"#{key}_cents" => nil, to_string(key) => nil}

  def money(key, cents) when is_integer(cents),
    do: %{"#{key}_cents" => cents, to_string(key) => cents / 100}

  @doc "Errors made plain: changesets become `%{\"field\" => [\"message\"]}`."
  def error(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(inspect_value(value)))
      end)
    end)
  end

  def error(reason) when is_binary(reason), do: reason
  def error(reason) when is_atom(reason), do: Atom.to_string(reason)
  def error(reason), do: inspect(reason)

  defp inspect_value(value) when is_binary(value) or is_number(value) or is_atom(value), do: value
  defp inspect_value(value), do: inspect(value)

  defp loaded?(%Ecto.Association.NotLoaded{}), do: false
  defp loaded?(_), do: true
end
