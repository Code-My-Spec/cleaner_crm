# Ecto.Query.Builder.Update



## escape/3

Escapes a list of quoted expressions.

    iex> escape([], [], __ENV__)
    {[], [], []}

    iex> escape([set: []], [], __ENV__)
    {[], [], []}

    iex> escape(quote(do: ^[set: []]), [], __ENV__)
    {[], [set: []], []}

    iex> escape(quote(do: [set: ^[foo: 1]]), [], __ENV__)
    {[], [set: [foo: 1]], []}

    iex> escape(quote(do: [set: [foo: ^1]]), [], __ENV__)
    {[], [set: [foo: 1]], []}

## build/4

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/2

The callback applied by `build/4` to build the query.

## update!/4

If there are interpolated updates at compile time,
we need to handle them at runtime. We do such in
this callback.