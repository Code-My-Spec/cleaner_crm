defmodule CleanerCrmMcp.Args do
  @moduledoc """
  Small helpers for tool `call/2` implementations. Arguments arrive already
  validated and coerced (see `CleanerCrmMcp.Catalog.coerce/2`), so these are
  mostly about optional values and money.
  """

  @doc "The value of `key`, or `default` when it was not given."
  def get(args, key, default \\ nil), do: Map.get(args, key, default)

  @doc "Dollars (number) to integer cents. `nil` stays `nil`."
  def to_cents(nil), do: nil
  def to_cents(dollars) when is_integer(dollars), do: dollars * 100
  def to_cents(dollars) when is_float(dollars), do: round(dollars * 100)

  @doc """
  Keeps only the given keys that are present, renaming string keys to atoms
  (handy for building attrs for a context `create_*`/`update_*` call).
  """
  def take(args, keys) do
    for key <- keys, Map.has_key?(args, key), into: %{} do
      {String.to_existing_atom(key), Map.fetch!(args, key)}
    end
  end
end
