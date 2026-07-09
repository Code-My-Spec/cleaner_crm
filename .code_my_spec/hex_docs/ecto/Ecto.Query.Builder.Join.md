# Ecto.Query.Builder.Join



## escape/3

Escapes a join expression (not including the `on` expression).

It returns a tuple containing the binds, the on expression (if available)
and the association expression.

## Examples

    iex> escape(quote(do: x in "foo"), [], __ENV__)
    {:x, {"foo", nil}, nil, nil, []}

    iex> escape(quote(do: "foo"), [], __ENV__)
    {:_, {"foo", nil}, nil, nil, []}

    iex> escape(quote(do: x in Sample), [], __ENV__)
    {:x, {nil, Sample}, nil, nil, []}

    iex> escape(quote(do: x in __MODULE__), [], __ENV__)
    {:x, {nil, __MODULE__}, nil, nil, []}

    iex> escape(quote(do: x in {"foo", :sample}), [], __ENV__)
    {:x, {"foo", :sample}, nil, nil, []}

    iex> escape(quote(do: x in {"foo", Sample}), [], __ENV__)
    {:x, {"foo", Sample}, nil, nil, []}

    iex> escape(quote(do: x in {"foo", __MODULE__}), [], __ENV__)
    {:x, {"foo", __MODULE__}, nil, nil, []}

    iex> escape(quote(do: c in assoc(p, :comments)), [p: 0], __ENV__)
    {:c, nil, {0, :comments}, nil, []}

    iex> escape(quote(do: x in fragment("foo")), [], __ENV__)
    {:x, {:{}, [], [:fragment, [], [raw: "foo"]]}, nil, nil, []}

## join!/1

Called at runtime to check dynamic joins.

## build/10

Builds a quoted expression.

The quoted expression should evaluate to a query at runtime.
If possible, it does all calculations at compile time to avoid
runtime work.

## apply/4

Applies the join expression to the query.

## runtime_aliases/3

Called at runtime to build aliases.

## join!/7

Called at runtime to build a join.

## qual!/1

Called at runtime to check dynamic qualifier.