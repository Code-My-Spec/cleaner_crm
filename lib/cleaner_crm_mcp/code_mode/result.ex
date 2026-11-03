defmodule CleanerCrmMcp.CodeMode.Result do
  @moduledoc """
  The outcome of one script evaluation.

    * `value` — what the script returned (plain Elixir terms), `nil` when it
      returned nothing.
    * `prints` — lines written with `print(...)`, in order (kept even when the
      script then fails).
    * `error` — `nil`, or `%{kind: atom, message: String.t()}` where kind is one
      of `:compile`, `:runtime`, `:rejected_call`, `:instruction_budget`,
      `:call_depth`, `:result_too_large`, `:sandboxed`, `:timeout`, `:crashed`.
  """

  @type t :: %__MODULE__{
          value: term(),
          prints: [String.t()],
          error: nil | %{kind: atom(), message: String.t()}
        }

  defstruct value: nil, prints: [], error: nil

  def ok?(%__MODULE__{error: nil}), do: true
  def ok?(%__MODULE__{}), do: false
end
