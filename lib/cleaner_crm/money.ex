defmodule CleanerCrm.Money do
  @moduledoc """
  Formats integer cents for display, per the money-handling ADR: every
  amount is stored and computed as integer cents, and this is the only
  place a dollar string gets built.
  """

  @doc """
  Formats integer cents as `"$X.XX"`, with thousands separators. `nil`
  is treated as zero.

  ## Examples

      iex> CleanerCrm.Money.format_cents(18_000)
      "$180.00"

      iex> CleanerCrm.Money.format_cents(nil)
      "$0.00"
  """
  @spec format_cents(integer() | nil) :: String.t()
  def format_cents(nil), do: format_cents(0)

  def format_cents(cents) when is_integer(cents) do
    sign = if cents < 0, do: "-", else: ""
    dollars = div(abs(cents), 100)
    remainder = rem(abs(cents), 100)

    "#{sign}$#{group_thousands(dollars)}.#{pad_cents(remainder)}"
  end

  defp pad_cents(remainder), do: remainder |> Integer.to_string() |> String.pad_leading(2, "0")

  defp group_thousands(dollars) do
    dollars
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
end
