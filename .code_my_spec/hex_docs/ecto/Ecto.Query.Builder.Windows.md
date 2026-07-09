# Ecto.Query.Builder.Windows



## escape/4

Escapes a window params.

## Examples

    iex> escape(quote do [order_by: [desc: 13]] end, {[], %{}}, [x: 0], __ENV__)
    {[order_by: [desc: 13]], [], {[], %{}}}

## build/4

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## runtime!/4

Invoked for runtime windows.

## apply/2

The callback applied by `build/4` to build the query.