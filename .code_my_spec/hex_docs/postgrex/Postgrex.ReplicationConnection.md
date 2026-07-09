# Postgrex.ReplicationConnection



## call/3

Calls the given replication server.

## start_link/3

Starts a replication process with the given callback `module`.

## Options

The options that this function accepts are the same as those
accepted by `Postgrex.start_link/1`, except for `:idle_interval`.

It also accepts extra options for connection management, documented below.
Also note this function also automatically set `:replication` to `"database"`
as part of the connection `:parameters` if none is set yet.

### Connection options

  * `:sync_connect` - controls if the connection should be established on boot
    or asynchronously right after boot. Defaults to `true`.

  * `:auto_reconnect` - automatically attempt to reconnect to the database
    in event of a disconnection. See the
    [note about async connect and auto-reconnects](#module-async-connect-and-auto-reconnects)
    above. Defaults to `false`, which means the process terminates.

  * `:reconnect_backoff` - time (in ms) between reconnection attempts when
    `:auto_reconnect` is enabled. Defaults to `500`.

## encode_lsn/1

Returns the string representation of an LSN value, given its integer representation.

It returns `:error` if the provided integer falls outside the range for a valid
unsigned 64-bit integer.

## Log Sequence Numbers

PostgreSQL uses two representations for the Log Sequence Number (LSN):

  * An unsigned 64-bit integer. Used internally by PostgreSQL and sent in the XLogData
  replication messages.

  * A string of two hexadecimal numbers of up to eight digits each, separated
  by a slash. e.g. `1/F73E0220`. This is the form accepted by `start_replication/2`.

For more information on Log Sequence Numbers, see
[PostgreSQL pg_lsn docs](https://www.postgresql.org/docs/current/datatype-pg-lsn.html) and
[PostgreSQL WAL internals docs](https://www.postgresql.org/docs/current/wal-internals.html).

## decode_lsn/1

Returns the integer representation of an LSN value, given its string representation.

It returns `:error` if the provided string is not a valid LSN.

## Log Sequence Numbers

PostgreSQL uses two representations for the Log Sequence Number (LSN):

  * An unsigned 64-bit integer. Used internally by PostgreSQL and sent in the XLogData
  replication messages.

  * A string of two hexadecimal numbers of up to eight digits each, separated
  by a slash. e.g. `1/F73E0220`. This is the form accepted by `start_replication/2`.

For more information on Log Sequence Numbers, see
[PostgreSQL pg_lsn docs](https://www.postgresql.org/docs/current/datatype-pg-lsn.html) and
[PostgreSQL WAL internals docs](https://www.postgresql.org/docs/current/wal-internals.html).