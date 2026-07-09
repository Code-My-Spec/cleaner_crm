# Credo.Check.Refactor.ABCSize



## abc_size_for/2

Returns the ABC size for the block inside the given AST, which is expected
to represent a function or macro definition.

    iex> {:def, [line: 1],
    ...>   [
    ...>     {:first_fun, [line: 1], nil},
    ...>     [do: {:=, [line: 2], [{:x, [line: 2], nil}, 1]}]
    ...>   ]
    ...> } |> Credo.Check.Refactor.ABCSize.abc_size
    1.0