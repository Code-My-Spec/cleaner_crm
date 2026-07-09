# Ecto.Query.Builder.CTE



## escape/2

Escapes the CTE name.

    iex> escape(quote(do: "FOO"), __ENV__)
    "FOO"

## build/6

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/5

The callback applied by `build/4` to build the query.