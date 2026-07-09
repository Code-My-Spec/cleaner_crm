# Ecto.Query.Builder.OrderBy



## valid_direction?/1

Returns `true` if term is a valid order_by direction; otherwise returns `false`.

## Examples

    iex> valid_direction?(:asc)
    true

    iex> valid_direction?(:desc)
    true

    iex> valid_direction?(:invalid)
    false

## escape/5

Escapes an order by query.

The query is escaped to a list of `{direction, expression}`
pairs at runtime. Escaping also validates direction is one of
`:asc`, `:asc_nulls_last`, `:asc_nulls_first`, `:desc`,
`:desc_nulls_last` or `:desc_nulls_first`.

## Examples

    iex> escape(:order_by, quote do [x.x, desc: 13] end, {[], %{}}, [x: 0], __ENV__)
    {[asc: {:{}, [], [{:{}, [], [:., [], [{:{}, [], [:&, [], [0]]}, :x]]}, [], []]},
      desc: 13],
     {[], %{}}}

## quoted_dir!/2

Checks the variable is a quoted direction at compilation time or
delegate the check to runtime for interpolation.

## dir!/2

Called at runtime to verify the direction.

## field!/2

Called at runtime to verify a field.

## order_by_or_distinct!/4

Shared between order_by and distinct.

## order_by!/5

Called at runtime to assemble order_by.

## build/5

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/3

The callback applied by `build/4` to build the query.

## update_order_bys/3

Updates the `order_bys` value for a query.