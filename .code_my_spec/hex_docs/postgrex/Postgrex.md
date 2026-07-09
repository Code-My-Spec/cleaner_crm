# Postgrex

PostgreSQL driver for Elixir.

Postgrex is a partial implementation of the Postgres [frontend/backend
message protocol](https://www.postgresql.org/docs/current/protocol.html).
It performs wire messaging in Elixir, as opposed to binding to a library
such as `libpq` in C.

A Postgrex query is performed as "[extended query](https://www.postgresql.org/docs/current/protocol-flow.html#PROTOCOL-FLOW-EXT-QUERY)".
An "extended query"  involves separate server-side parse, bind, and execute
stages, each of which may be re-used for efficiency. For example, libraries
like Ecto caches queries, so a query only has to be parsed and planned once.
This is all done via wire messaging, without relying on `PREPARE q AS (...)`
and `EXECUTE q()` SQL statements directly.

This module handles the connection to PostgreSQL, providing support
for queries, transactions, connection backoff, logging, pooling and
more.

Note that the notifications API (pub/sub) supported by PostgreSQL is
handled by `Postgrex.Notifications`. Hence, to use this feature,
you need to start a separate (notifications) connection.

## query!/4

Runs an (extended) query and returns the result or raises `Postgrex.Error` if
there was an error. See `query/3`.

## prepare!/4

Prepares an (extended) query and returns the prepared query or raises
`Postgrex.Error` if there was an error. See `prepare/4`.

## prepare_execute!/5

Prepares and runs a query and returns the result or raises
`Postgrex.Error` if there was an error. See `prepare_execute/5`.

## execute!/4

Runs an (extended) prepared query and returns the result or raises
`Postgrex.Error` if there was an error. See `execute/4`.

## close!/3

Closes an (extended) prepared query and returns `:ok` or raises
`Postgrex.Error` if there was an error. See `close/3`.

## parameters/2

Rollback a transaction, does not return.

Aborts the current transaction fun. If inside multiple `transaction/3`
functions, bubbles up to the top level.

## Example

    {:error, :oops} = Postgrex.transaction(pid, fn(conn) ->
      DBConnection.rollback(conn, :bar)
      IO.puts "never reaches here!"
    end)

## child_spec/1

Returns a supervisor child specification for a DBConnection pool.