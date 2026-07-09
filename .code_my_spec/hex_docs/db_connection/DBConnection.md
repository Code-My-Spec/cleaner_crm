# DBConnection

A behaviour module for implementing efficient database connection
client processes, pools and transactions.

`DBConnection` handles callbacks differently to most behaviours. Some
callbacks will be called in the calling process, with the state
copied to and from the calling process. This is useful when the data
for a request is large and means that a calling process can interact
with a socket directly.

A side effect of this is that query handling can be written in a
simple blocking fashion, while the connection process itself will
remain responsive to OTP messages and can enqueue and cancel queued
requests.

If a request or series of requests takes too long to handle in the
client process a timeout will trigger and the socket can be cleanly
disconnected by the connection process.

If a calling process waits too long to start its request it will
timeout and its request will be cancelled. This prevents requests
building up when the database can not keep up.

If no requests are received for an idle interval, the pool will
ping all stale connections which can then ping the database to keep
the connection alive.

Should the connection be lost, attempts will be made to reconnect with
(configurable) exponential random backoff to reconnect. All state is
lost when a connection disconnects but the process is reused.

The `DBConnection.Query` protocol provide utility functions so that
queries can be encoded and decoded without blocking the connection or pool.

## Connection pools

DBConnection connections support using different pools via the `:pool` option
passed to `start_link/2`. The default pool is `DBConnection.ConnectionPool`.
Another supported pool that is commonly used for tests is `DBConnection.Ownership`.

For now, using *custom* pools is not supported since the API for pools is not
public.

## Errors

Most functions in this module raise a `DBConnection.ConnectionError` exception
when failing to check out a connection from the pool.

## __using__/1

Use `DBConnection` to set the behaviour.

## start_link/2

Starts and links to a database connection process.

By default the `DBConnection` starts a pool with a single connection.
The size of the pool can be increased with `:pool_size`. A separate
pool can be given with the `:pool` option.

### Options

  * `:after_connect` - A function to run on connect using `run/3`, either
    a 1-arity fun, `{module, function, args}` with `t:DBConnection.t/0` prepended
    to `args` or `nil` (default: `nil`)

  * `:after_connect_timeout` - The maximum time allowed to perform
    function specified by `:after_connect` option (default: `15_000`)

  * `:backoff_min` - The minimum backoff interval (default: `1_000`)

  * `:backoff_max` - The maximum backoff interval (default: `30_000`)

  * `:backoff_type` - The backoff strategy, `:stop` for no backoff and
    to stop, `:exp` for exponential, `:rand` for random and `:rand_exp` for
    random exponential (default: `:rand_exp`)

  * `:checkout_retries` - The number of times to checkout a new connection
    whenever the operation fails because the database disconnected. Note
    not all operations can be retried and each adapter specifies which
    operations are safe to retry

  * `:configure` - A function to run before every connect attempt to
    dynamically configure the options, either a 1-arity fun,
    `{module, function, args}` or `nil`. This function is called *in the
    connection process*. For more details, see
    [Connection Configuration Callback](#start_link/2-connection-configuration-callback)

  * `:connection_listeners` - A list of process destinations to send
    notification messages whenever a connection is connected or disconnected.
    See "Connection listeners" below

  * `:idle_interval` - Controls the frequency we check for idle connections
    in the pool. We then notify each idle connection to ping the database.
    In practice, the ping happens within `idle_interval <= ping < 2 * idle_interval`.
    Defaults to 1000ms.

  * `:idle_limit` - The number of connections to ping on each `:idle_interval`.
    Defaults to the pool size (all connections).

  * `:max_restarts` and `:max_seconds` - Configures the `:max_restarts` and
    `:max_seconds` for the connection pool supervisor (see the `Supervisor` docs).
    Typically speaking the connection process doesn't terminate, except due to
    faults in DBConnection. However, if backoff has been disabled, then they
    also terminate whenever a connection is disconnected (for instance, due to
    client or server errors)

  * `:max_lifetime` - The number of ms the connection is allowed to live.
    It is a range so you can jitter/spread disconnections over some time period.
    For example, to have a max lifetime between 8 and 9 minutes, you can set it
    to `480_000..540_000`. Because the timer is started *after* the connection
    to the database is established, the connection may live for slightly longer.
    If the connection is idle, the worst case wait is of
    `540_000 + 2 * idle_interval`. If the connection is in use, it may last as
    long as the connection is checked out over the max period. Default is `nil`.
    Enabling this option requires a backoff to be set, so connections can properly
    reconnect.

  * `:name` - A name to register the started process (see the `:name` option
    in `GenServer.start_link/3`)

  * `:pool` - Chooses the pool to be started (default: `DBConnection.ConnectionPool`).
    See ["Connection pools"](#module-connection-pools).

  * `:pool_size` - Chooses the size of the pool. Must be greater or equal to 1. (default: `1`)

  * `:queue_target` and `:queue_interval` - See "Queue config" below

  * `:show_sensitive_data_on_connection_error` - By default, `DBConnection`
    hides all information during connection errors to avoid leaking credentials
    or other sensitive information. You can set this option if you wish to
    see complete errors and stacktraces during connection errors

### Example

    {:ok, conn} = DBConnection.start_link(mod, [idle_interval: 5_000])

## Queue config

Handling requests is done through a queue. When DBConnection is
started, there are two relevant options to control the queue:

  * `:queue_target` in milliseconds, defaults to 50ms
  * `:queue_interval` in milliseconds, defaults to 2000ms

Our goal is to wait at most `:queue_target` for a connection.
If all connections checked out during a `:queue_interval` takes
more than `:queue_target`, then we double the `:queue_target`.
If checking out connections take longer than the new target,
then we start dropping messages.

For example, by default our target is 50ms. If all connections
checkouts take longer than 50ms for a whole second, we double
the target to 100ms and we start dropping messages if the
time to checkout goes above the new limit.

This allows us to better plan for overloads as we can refuse
requests before they are sent to the database, which would
otherwise increase the burden on the database, making the
overload worse.

## Connection listeners

The `:connection_listeners` option allows one or more processes to be notified
whenever a connection is connected or disconnected. A listener may be a remote
or local PID, a locally registered name, or a tuple in the form of
`{registered_name, node}` for a registered name at another node.

Each listener process may receive the following messages where `pid`
identifies the connection process:

  * `{:connected, pid}`
  * `{:disconnected, pid}`

If the value of `:connection_listeners` is a tuple like `{listeners, term}`, then
the messages are these instead:

  * `{:connected, pid, term}`
  * `{:disconnected, pid, term}`

Note the disconnected messages are not guaranteed to be delivered if the
`pid` for connection crashes. So it is recommended to monitor the connected
`pid` if you want to track all disconnections.

Here is an example of a `:connection_listener` implementation:

    defmodule DBConnectionListener do
      use GenServer

      def start_link(opts) do
        GenServer.start_link(__MODULE__, [], opts)
      end

      def get_notifications(pid) do
        GenServer.call(pid, :read_state)
      end

      @impl true
      def init(stack) when is_list(stack) do
        {:ok, stack}
      end

      @impl true
      def handle_call(:read_state, _from, state) do
        {:reply, state, state}
      end

      @impl true
      def handle_info({:connected, _pid} = msg, state) do
        {:noreply, [msg | state]}
      end

      @impl true
      def handle_info({_other_states, _pid} = msg, state) do
        {:noreply, [msg | state]}
      end
    end

You can then start it, pass the PID in the `connection_listeners`
option on `DBConnection.start_link/2` and, when needed, can query the notifications:

    {:ok, pid} = DBConnectionListener.start_link([])
    {:ok, _conn} = DBConnection.start_link(SomeModule, [connection_listeners: [pid]])
    notifications = DBConnectionListener.get_notifications(pid)

### Tagging messages

If you pass `{listeners, tag}` as an option, you can specify an arbitrary `tag` term that will
be sent alongside all `:connected`/`:disconnected` messages. This is useful if you
want to track information about the pool a connection belongs to or any other information.

This feature is available since v2.6.0. Before this version `:connection_listeners` only
accepted a list of listener processes.

## Connection Configuration Callback

The `:configure` function will be called before each individual connection to the
database is made. It receives all of the options provided to `start_link/2` as well
as an additional generated value named `:pool_index`. The returned value will be
passed as the options into the appropriate `:connect` callback. This provides a way
for the user to dynamically configure the connection options.

`:pool_index` is an integer in `1..pool_size` that represents the current connection's
place in the enumeration of all of the pool's connections. It can be used, for example,
to configure a unique database per connection when asynchronous tests cannot be performed
on a single database.

The allowed callbacks are:

  * A 1-arity function that receives the options from `start_link/2` as well as
    `:pool_index`
  * `{module, function, args}` where the options from `start_link/2` as well as
    `:pool_index` are prepended to `args` before the function is called
  * `nil` if you do not want to modify the existing options

## Telemetry

A `[:db_connection, :connection_error]` event is published whenever a
connection checkout receives a `%DBConnection.ConnectionError{}`.
This event is emitted from the process that attempts to checkout the
connection.

Measurements:

  * `:count` - A fixed-value measurement which always measures 1.

Metadata

  * `:error` - The `DBConnection.ConnectionError` struct which triggered the event.

  * `:opts` - All options given to the pool operation

You may also consume `[:db_connection, :connected]` and `[:db_connection, :disconnected]`
events by spawning a `DBConnection.TelemetryListener` process that subscribes to the pool
and emits them in a robust manner.

## child_spec/2

Creates a supervisor child specification for a pool of connections.

See `start_link/2` for options.

## available_start_options/0

Returns the names of all possible options that you can pass to `start_link/2`.

This is mostly useful for library authors that base their library on top of
`DBConnection`, since they can use the return value of this function to perform
validation on options only passing down these options to DBConnection.

See also `t:start_option/0`.

## available_connection_options/0

Returns the names of all possible options that you can pass to most functions
in this module.

This is mostly useful for library authors that base their library on top of
`DBConnection`, since they can use the return value of this function to perform
validation on options only passing down these options to DBConnection.

See also `t:connection_option/0`.

## disconnect_all/3

Forces all connections in the pool to disconnect within the given interval
in milliseconds.

Once this function is called, the pool will disconnect all of its connections
as they are checked in or as they are pinged. Checked in and idle connections
will be randomly disconnected within the given time interval.

If the connection has a backoff configured (which is the case by default),
disconnecting means an attempt at a new connection will be done immediately
after, without starting a new process for each connection. However, if backoff
has been disabled, the connection process will terminate. In such cases,
disconnecting all connections may cause the pool supervisor to restart
depending on the max_restarts/max_seconds configuration of the pool,
so you will want to set those carefully.

## prepare/3

Prepare a query with a database connection for later execution.

It returns `{:ok, query}` on success or `{:error, exception}` if there was
an error.

The returned `query` can then be passed to `execute/4` and/or `close/3`

### Options

  * `:queue` - Whether to block waiting in an internal queue for the
  connection's state (boolean, default: `true`). See "Queue config" in
  `start_link/2` docs
  * `:timeout` - The maximum time that the caller is allowed to perform
  this operation (default: `15_000`)
  * `:deadline` - If set, overrides `:timeout` option and specifies absolute
  monotonic time in milliseconds by which caller must perform operation.
  See `System` module documentation for more information on monotonic time
  (default: `nil`)
  * `:log` - A function to log information about a call, either
  a 1-arity fun, `{module, function, args}` with `t:DBConnection.LogEntry.t/0`
  prepended to `args` or `nil`. See `DBConnection.LogEntry` (default: `nil`)

The pool and connection module may support other options. All options
are passed to `c:handle_prepare/3`.

### Example

    DBConnection.transaction(pool, fn conn ->
      query = %Query{statement: "SELECT * FROM table"}
      query = DBConnection.prepare!(conn, query)
      try do
        DBConnection.execute!(conn, query, [])
      after
        DBConnection.close(conn, query)
      end
    end)

## prepare!/3

Prepare a query with a database connection and return the prepared
query. An exception is raised on error.

See `prepare/3`.

## prepare_execute/4

Prepare a query and execute it with a database connection and return both the
prepared query and the result, `{:ok, query, result}` on success or
`{:error, exception}` if there was an error.

The returned `query` can be passed to `execute/4` and `close/3`.

### Options

  * `:queue` - Whether to block waiting in an internal queue for the
  connection's state (boolean, default: `true`). See "Queue config" in
  `start_link/2` docs
  * `:timeout` - The maximum time that the caller is allowed to perform
  this operation (default: `15_000`)
  * `:deadline` - If set, overrides `:timeout` option and specifies absolute
  monotonic time in milliseconds by which caller must perform operation.
  See `System` module documentation for more information on monotonic time
  (default: `nil`)
  * `:log` - A function to log information about a call, either
  a 1-arity fun, `{module, function, args}` with `t:DBConnection.LogEntry.t/0`
  prepended to `args` or `nil`. See `DBConnection.LogEntry` (default: `nil`)

### Example

    query                = %Query{statement: "SELECT id FROM table WHERE id=$1"}
    {:ok, query, result} = DBConnection.prepare_execute(conn, query, [1])
    {:ok, result2}       = DBConnection.execute(conn, query, [2])
    :ok                  = DBConnection.close(conn, query)

## prepare_execute!/4

Prepare a query and execute it with a database connection and return both the
prepared query and result. An exception is raised on error.

See `prepare_execute/4`.

## execute/4

Execute a prepared query with a database connection and return
`{:ok, query, result}` on success or `{:error, exception}` if there was an error.

If the query is not prepared on the connection an attempt may be made to
prepare it and then execute again.

### Options

  * `:queue` - Whether to block waiting in an internal queue for the
  connection's state (boolean, default: `true`). See "Queue config" in
  `start_link/2` docs
  * `:timeout` - The maximum time that the caller is allowed to perform
  this operation (default: `15_000`)
  * `:deadline` - If set, overrides `:timeout` option and specifies absolute
  monotonic time in milliseconds by which caller must perform operation.
  See `System` module documentation for more information on monotonic time
  (default: `nil`)
  * `:log` - A function to log information about a call, either
  a 1-arity fun, `{module, function, args}` with `t:DBConnection.LogEntry.t/0`
  prepended to `args` or `nil`. See `DBConnection.LogEntry` (default: `nil`)

The pool and connection module may support other options. All options
are passed to `handle_execute/4`.

See `prepare/3`.

## execute!/4

Execute a prepared query with a database connection and return the
result. Raises an exception on error.

See `execute/4`

## close/3

Close a prepared query on a database connection and return `{:ok, result}` on
success or `{:error, exception}` on error.

This function should be used to free resources held by the connection
process and/or the database server.

## Options

  * `:queue` - Whether to block waiting in an internal queue for the
  connection's state (boolean, default: `true`). See "Queue config" in
  `start_link/2` docs
  * `:timeout` - The maximum time that the caller is allowed to perform
  this operation (default: `15_000`)
  * `:deadline` - If set, overrides `:timeout` option and specifies absolute
  monotonic time in milliseconds by which caller must perform operation.
  See `System` module documentation for more information on monotonic time
  (default: `nil`)
  * `:log` - A function to log information about a call, either
  a 1-arity fun, `{module, function, args}` with `t:DBConnection.LogEntry.t/0`
  prepended to `args` or `nil`. See `DBConnection.LogEntry` (default: `nil`)

The pool and connection module may support other options. All options
are passed to `c:handle_close/3`.

See `prepare/3`.

## close!/3

Close a prepared query on a database connection and return the result. Raises
an exception on error.

See `close/3`.

## run/3

Acquire a lock on a connection and run a series of requests on it.

The return value of this function is the return value of `fun`.

To use the locked connection call the request with the connection
reference passed as the single argument to the `fun`. If the
connection disconnects all future calls using that connection
reference will fail.

`run/3` and `transaction/3` can be nested multiple times but a
`transaction/3` call inside another `transaction/3` will be treated
the same as `run/3`.

> #### Checkout failures {: .warning}
>
> If we cannot check out a connection from the pool, this function raises a
> `DBConnection.ConnectionError` exception.
> If you want to handle these cases, you should rescue
> `DBConnection.ConnectionError` exceptions when using `run/3`.

## Options

  * `:queue` - Whether to block waiting in an internal queue for the
  connection's state (boolean, default: `true`). See "Queue config" in
  `start_link/2` docs
  * `:timeout` - The maximum time that the caller is allowed to perform
  this operation (default: `15_000`)
  * `:deadline` - If set, overrides `:timeout` option and specifies absolute
  monotonic time in milliseconds by which caller must perform operation.
  See `System` module documentation for more information on monotonic time
  (default: `nil`)

The pool may support other options.

## Example

    {:ok, res} = DBConnection.run(conn, fn conn ->
      DBConnection.execute!(conn, query, [])
    end)

## transaction/3

Acquire a lock on a connection and run a series of requests inside a
transaction. The result of the transaction fun is return inside an `:ok`
tuple: `{:ok, result}`.

To use the locked connection call the request with the connection
reference passed as the single argument to the `fun`. If the
connection disconnects all future calls using that connection
reference will fail.

`run/3` and `transaction/3` can be nested multiple times. If a transaction is
rolled back or a nested transaction `fun` raises the transaction is marked as
failed. All calls except `run/3`, `transaction/3`, `rollback/2`, `close/3` and
`close!/3` will raise an exception inside a failed transaction until the outer
transaction call returns. All `transaction/3` calls will return
`{:error, :rollback}` if the transaction failed or connection closed and
`rollback/2` is not called for that `transaction/3`.

### Options

  * `:queue` - Whether to block waiting in an internal queue for the
  connection's state (boolean, default: `true`). See "Queue config" in
  `start_link/2` docs
  * `:timeout` - The maximum time that the caller is allowed to perform
  this operation (default: `15_000`)
  * `:deadline` - If set, overrides `:timeout` option and specifies absolute
  monotonic time in milliseconds by which caller must perform operation.
  See `System` module documentation for more information on monotonic time
  (default: `nil`)
  * `:log` - A function to log information about begin, commit and rollback
  calls made as part of the transaction, either a 1-arity fun,
  `{module, function, args}` with `t:DBConnection.LogEntry.t/0` prepended to
  `args` or `nil`. See `DBConnection.LogEntry` (default: `nil`)

The pool and connection module may support other options. All options
are passed to `c:handle_begin/2`, `c:handle_commit/2` and
`c:handle_rollback/2`.

### Example

    {:ok, res} = DBConnection.transaction(conn, fn conn ->
      DBConnection.execute!(conn, query, [])
    end)

## rollback/2

Rollback a database transaction and release lock on connection.

When inside of a `transaction/3` call does a non-local return, using a
`throw/1` to cause the transaction to enter a failed state and the
`transaction/3` call returns `{:error, reason}`. If `transaction/3` calls are
nested the connection is marked as failed until the outermost transaction call
does the database rollback.

### Example

    {:error, :oops} = DBConnection.transaction(pool, fun(conn) ->
      DBConnection.rollback(conn, :oops)
    end)

## status/2

Return the transaction status of a connection.

The callback implementation should return the transaction status according to
the database, and not make assumptions based on client-side state.

This function will raise a `DBConnection.ConnectionError` when called inside a
deprecated `transaction/3`.

### Options

See module documentation. The pool and connection module may support other
options. All options are passed to `c:handle_status/2`.

### Example

    # outside of the transaction, the status is `:idle`
    DBConnection.status(conn) #=> :idle

    DBConnection.transaction(conn, fn conn ->
      DBConnection.status(conn) #=> :transaction

      # run a query that will cause the transaction to rollback, e.g.
      # uniqueness constraint violation
      DBConnection.execute(conn, bad_query, [])

      DBConnection.status(conn) #=> :error
    end)

    DBConnection.status(conn) #=> :idle

## prepare_stream/4

Create a stream that will prepare a query, execute it and stream results
using a cursor.

### Options

  * `:queue` - Whether to block waiting in an internal queue for the
  connection's state (boolean, default: `true`). See "Queue config" in
  `start_link/2` docs
  * `:timeout` - The maximum time that the caller is allowed to perform
  this operation (default: `15_000`)
  * `:deadline` - If set, overrides `:timeout` option and specifies absolute
  monotonic time in milliseconds by which caller must perform operation.
  See `System` module documentation for more information on monotonic time
  (default: `nil`)
  * `:log` - A function to log information about a call, either
  a 1-arity fun, `{module, function, args}` with `t:DBConnection.LogEntry.t/0`
  prepended to `args` or `nil`. See `DBConnection.LogEntry` (default: `nil`)

The pool and connection module may support other options. All options
are passed to `c:handle_prepare/3`, `c:handle_close/3`, `c:handle_declare/4`,
and `c:handle_deallocate/4`.

### Example

    {:ok, results} = DBConnection.transaction(conn, fn conn ->
      query = %Query{statement: "SELECT id FROM table"}
      stream = DBConnection.prepare_stream(conn, query, [])
      Enum.to_list(stream)
    end)

## stream/4

Create a stream that will execute a prepared query and stream results using a
cursor.

### Options

  * `:queue` - Whether to block waiting in an internal queue for the
  connection's state (boolean, default: `true`). See "Queue config" in
  `start_link/2` docs
  * `:timeout` - The maximum time that the caller is allowed to perform
  this operation (default: `15_000`)
  * `:deadline` - If set, overrides `:timeout` option and specifies absolute
  monotonic time in milliseconds by which caller must perform operation.
  See `System` module documentation for more information on monotonic time
  (default: `nil`)
  * `:log` - A function to log information about a call, either
  a 1-arity fun, `{module, function, args}` with `t:DBConnection.LogEntry.t/0`
  prepended to `args` or `nil`. See `DBConnection.LogEntry` (default: `nil`)

The pool and connection module may support other options. All options
are passed to `c:handle_declare/4` and `c:handle_deallocate/4`.

### Example

    DBConnection.transaction(pool, fn conn ->
      query = %Query{statement: "SELECT id FROM table"}
      query = DBConnection.prepare!(conn, query)
      try do
        stream = DBConnection.stream(conn, query, [])
        Enum.to_list(stream)
      after
        # Make sure query is closed!
        DBConnection.close(conn, query)
      end
    end)

## reduce/3

Reduces a previously built stream or prepared stream.

## connection_module/1

Returns the connection module used by the given connection pool.

When given a process that is not a connection pool, returns an `:error`.

## get_connection_metrics/2

Returns connection metrics as a list in the shape of:

    [%{
      source: {:pool | :proxy, pid()},
      ready_conn_count: non_neg_integer(),
      checkout_queue_length: non_neg_integer()
    }]