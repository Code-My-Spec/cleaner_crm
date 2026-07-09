# Ecto.Adapters.SQL



## stream/4

Returns a stream that runs a custom SQL query on given repo when reduced.

In case of success it is a enumerable containing maps with at least two keys:

  * `:num_rows` - the number of rows affected

  * `:rows` - the result set as a list. `nil` may be returned
    instead of the list if the command does not yield any row
    as result (but still yields the number of affected rows,
    like a `delete` command without returning would)

In case of failure it raises an exception.

If the adapter supports a collectable stream, the stream may also be used as
the collectable in `Enum.into/3`. Behaviour depends on the adapter.

## Options

  * `:log` - When false, does not log the query
  * `:max_rows` - The number of rows to load from the database as we stream

## Examples

    iex> Ecto.Adapters.SQL.stream(MyRepo, "SELECT $1::integer + $2", [40, 2]) |> Enum.to_list()
    [%{rows: [[42]], num_rows: 1}]

## table_exists?/3

Checks if the given `table` exists.

Returns `true` if the `table` exists in the `repo`, otherwise `false`.
The table is checked against the current database/schema in the connection.

## first_non_ecto_stacktrace/3

Receives a stacktrace, and return the first N items before Ecto entries

This function is used by default in the `:log_stacktrace_mfa` config, with
a size of 1.