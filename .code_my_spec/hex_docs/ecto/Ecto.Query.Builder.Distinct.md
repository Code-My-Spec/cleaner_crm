# Ecto.Query.Builder.Distinct



## escape/4

Escapes a list of quoted expressions.

    iex> escape(quote do true end, {[], %{}}, [], __ENV__)
    {true, {[], %{}}}

    iex> escape(quote do [x.x, 13] end, {[], %{}}, [x: 0], __ENV__)
    {[asc: {:{}, [], [{:{}, [], [:., [], [{:{}, [], [:&, [], [0]]}, :x]]}, [], []]},
      asc: 13],
     {[], %{}}}

## distinct!/4

Called at runtime to verify distinct.

## build/4

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/2

The callback applied by `build/4` to build the query.