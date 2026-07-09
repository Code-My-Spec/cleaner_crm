# Ecto.Query.Builder.LimitOffset



## with_ties!/1

Validates `with_ties` at runtime.

## build/5

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/3

The callback applied by `build/4` to build the query.

## apply_limit/2

Applies the `with_ties` value to the `limit` struct.