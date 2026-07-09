# Ecto.Query.Builder.Lock



## escape/3

Escapes the lock code.

    iex> escape(quote(do: "FOO"), [], __ENV__)
    "FOO"

## build/4

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/2

The callback applied by `build/4` to build the query.