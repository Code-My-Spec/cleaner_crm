# Ecto.Query.Builder.GroupBy



## escape/5

Escapes a list of quoted expressions.

See `Ecto.Builder.escape/2`.

    iex> escape(:group_by, quote do [x.x, 13] end, {[], %{}}, [x: 0], __ENV__)
    {[{:{}, [], [{:{}, [], [:., [], [{:{}, [], [:&, [], [0]]}, :x]]}, [], []]},
      13],
     {[], %{}}}

## field!/2

Called at runtime to verify a field.

## group_or_partition_by!/4

Shared between group_by and partition_by.

## group_by!/4

Called at runtime to assemble group_by.

## build/4

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/2

The callback applied by `build/4` to build the query.