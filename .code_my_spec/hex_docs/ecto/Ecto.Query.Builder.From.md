# Ecto.Query.Builder.From



## escape/2

Handles from expressions.

The expressions may either contain an `in` expression or not.
The right side is always expected to Queryable.

## Examples

    iex> escape(quote(do: MySchema), __ENV__)
    {MySchema, []}

    iex> escape(quote(do: p in posts), __ENV__)
    {quote(do: posts), [p: 0]}

    iex> escape(quote(do: p in {"posts", MySchema}), __ENV__)
    {{"posts", MySchema}, [p: 0]}

    iex> escape(quote(do: [p, q] in posts), __ENV__)
    {quote(do: posts), [p: 0, q: 1]}

    iex> escape(quote(do: [_, _] in abc), __ENV__)
    {quote(do: abc), [_: 0, _: 1]}

    iex> escape(quote(do: other), __ENV__)
    {quote(do: other), []}

    iex> escape(quote(do: x() in other), __ENV__)
    ** (Ecto.Query.CompileError) binding list should contain only variables or `{as, var}` tuples, got: x()

## build/5

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## hint!/1

Validates hints at compile time and runtime

## apply/5

The callback applied by `build/2` to build the query.