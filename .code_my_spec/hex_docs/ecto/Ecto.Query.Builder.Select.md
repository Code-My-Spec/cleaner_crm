# Ecto.Query.Builder.Select



## escape/3

Escapes a select.

It allows tuples, lists and variables at the top level. Inside the
tuples and lists query expressions are allowed.

## Examples

    iex> escape({1, 2}, [], __ENV__)
    {{:{}, [], [:{}, [], [1, 2]]}, {[], %{take: %{}, subqueries: [], aliases: %{}}}}

    iex> escape([1, 2], [], __ENV__)
    {[1, 2], {[], %{take: %{}, subqueries: [], aliases: %{}}}}

    iex> escape(quote(do: x), [x: 0], __ENV__)
    {{:{}, [], [:&, [], [0]]}, {[], %{take: %{}, subqueries: [], aliases: %{}}}}

## fields!/2

Called at runtime to verify a field.

## map_key!/1

Called at runtime to verify a map key

## select!/5

Called at runtime for interpolated/dynamic selects.

## build/5

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/2

The callback applied by `build/5` to build the query.

## merge/2

The callback applied by `build/5` when merging.