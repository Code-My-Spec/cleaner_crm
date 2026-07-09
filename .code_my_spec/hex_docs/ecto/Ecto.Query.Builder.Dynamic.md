# Ecto.Query.Builder.Dynamic



## build/3

Builds a dynamic expression.

## fully_expand/2

Expands a dynamic expression for insertion into the given query.

## partially_expand/6

Expands a dynamic expression as part of an existing expression.

Any dynamic expression parameter is prepended and the parameters
list is not reversed. This is useful when the dynamic expression
is given in the middle of an expression.