# Ecto.Query.Builder.Preload



## escape/2

Escapes a preload.

A preload may be an atom, a list of atoms or a keyword list
nested as a rose tree.

    iex> escape(:foo, [])
    {[:foo], []}

    iex> escape([foo: :bar], [])
    {[foo: [:bar]], []}

    iex> escape([:foo, :bar], [])
    {[:foo, :bar], []}

    iex> escape([foo: [:bar, bar: :bat]], [])
    {[foo: [:bar, bar: [:bat]]], []}

    iex> escape([foo: {:^, [], ["external"]}], [])
    {[foo: "external"], []}

    iex> escape([foo: [:bar, {:^, [], ["external"]}], baz: :bat], [])
    {[foo: [:bar, "external"], baz: [:bat]], []}

    iex> escape([foo: {:c, [], nil}], [c: 1])
    {[], [foo: {1, []}]}

    iex> escape([foo: {{:c, [], nil}, bar: {:l, [], nil}}], [c: 1, l: 2])
    {[], [foo: {1, [bar: {2, []}]}]}

    iex> escape([foo: {:c, [], nil}, bar: {:l, [], nil}], [c: 1, l: 2])
    {[], [foo: {1, []}, bar: {2, []}]}

    iex> escape([foo: {{:c, [], nil}, :bar}], [c: 1])
    {[foo: [:bar]], [foo: {1, []}]}

    iex> escape([foo: [bar: {:c, [], nil}]], [c: 1])
    ** (Ecto.Query.CompileError) cannot preload join association `:bar` with binding `c` because parent preload is not a join association

## key!/1

Called at runtime to check dynamic preload keys.

## build/4

Applies the preloaded value into the query.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/3

The callback applied by `build/4` to build the query.

## preload!/2

Called at runtime to assemble preload.

## expand/2

Expands preloads at runtime.

## Examples

    iex> expand(:foo, [])
    {[:foo], []}

    iex> expand([foo: :bar], [])
    {[foo: :bar], []}

    iex> expand([:foo, :bar], [])
    {[:foo, :bar], []}

    iex> expand([foo: [:bar, bar: :bat]], [])
    {[foo: [:bar, bar: :bat]], []}

    iex> expand([:a, :b, c: [:d]], [])
    {[:a, :b, c: [:d]], []}

    iex> expand([foo: ["external"]], [])
    ** (ArgumentError) `"external"` is not a valid preload expression, expected an atom or a list.

    iex> require Ecto.Query
    iex> expand([b: Ecto.Query.dynamic([_a, b], b)], Ecto.Query.from(a in "a", join: b in "b", on: true))
    {[], [b: {1, []}]}

    iex> require Ecto.Query
    iex> expand(
    ...>   [b: {Ecto.Query.dynamic([_a, b], b), c: Ecto.Query.dynamic([_a, _b, c], c)}],
    ...>   Ecto.Query.from(a in "a", join: b in "b", on: true, join: c in "c", on: true)
    ...> )
    {[], [b: {1, [c: {2, []}]}]}