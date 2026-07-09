# Ecto.Repo

Defines a repository.

A repository maps to an underlying data store, controlled by the
adapter. For example, Ecto ships with a Postgres adapter that
stores data into a PostgreSQL database.

When used, the repository expects the `:otp_app` and `:adapter` as
option. The `:otp_app` should point to an OTP application that has
the repository configuration. For example, the repository:

    defmodule Repo do
      use Ecto.Repo,
        otp_app: :my_app,
        adapter: Ecto.Adapters.Postgres
    end

Could be configured with:

    config :my_app, Repo,
      database: "ecto_simple",
      username: "postgres",
      password: "postgres",
      hostname: "localhost"

Most of the configuration that goes into the `config` is specific
to the adapter. For this particular example, you can check
[`Ecto.Adapters.Postgres`](https://hexdocs.pm/ecto_sql/Ecto.Adapters.Postgres.html)
for more information. In spite of this, the following configuration values
are common across all adapters:

  * `:name`- The name of the Repo supervisor process. Notice that
    it must be unique across **all repo modules**

  * `:priv` - the directory where to keep repository data, like
    migrations, schema and more. Defaults to "priv/YOUR_REPO".
    It must always point to a subdirectory inside the priv directory

  * `:url` - an URL that specifies storage information. Read below
    for more information

  * `:log` - the log level used when logging the query with Elixir's
    Logger. Can be any of `Logger.level/0` values or `false`. If false,
    disables logging for that repository. Defaults to `:debug`

  * `:pool_size` - the size of the pool used by the connection module.
    Defaults to `10`

  * `:pool_count` - the number of pools to run concurrently,
    increase this option when the pool itself may be under contention.
    When running multiple pools, queries are randomly routed to different
    pools, without taking into account how many connections are available
    in each. So in some circumstances, you may be routed to a fully busy
    pool while others have connections available. The overall number of
    connections used will be `pool_size * pool_count`. Defaults to `1`

  * `:telemetry_prefix` - we recommend adapters to publish events
    using the [Telemetry](`:telemetry`) library. By default, the telemetry prefix
    is based on the module name, so if your module is called
    `MyApp.Repo`, the prefix will be `[:my_app, :repo]`. See the
    ["Telemetry Events"](#module-telemetry-events) section to see which events we recommend
    adapters to publish. Note that if you have multiple databases, you
    should keep the `:telemetry_prefix` consistent for each repo and
    use the `:repo` property in the event metadata for distinguishing
    between repos.

  * `:stacktrace`- when `true`, publishes the stacktrace in telemetry events
    and allows more advanced logging.

  * `:log_stacktrace_mfa` - A `{module, function, arguments}` tuple that customizes
    which part of the stacktrace is included in query logs. The specified function
    must accept at least two arguments (stacktrace and metadata) and return
    a filtered stacktrace. The metadata is a map with keys such as `:repo` and other
    adapter specific information. Additional arguments can be passed in the third
    element of the tuple. For `Ecto.Adapters.SQL`, defaults to
    `{Ecto.Adapters.SQL, :first_non_ecto_stacktrace, [1]}`, which filters the
    stacktrace to show only the first call originating from outside
    Ecto's internal code. Only relevant when `:stacktrace` is `true`.

## URLs

Repositories by default support URLs. For example, the configuration
above could be rewritten to:

    config :my_app, Repo,
      url: "ecto://postgres:postgres@localhost/ecto_simple"

The schema can be of any value and the path represents the database name.
The URL will be used generate the relevant Repo configuration values, such
as `:database`, `:username`, `:password`, `:hostname` and `:port`. These
values take precedence over those already specified in the Repo's configuration.

URL can include query parameters to override shared and adapter-specific
options, like `ssl`, `timeout` and `pool_size`. The following example
shows how to pass these configuration values:

    config :my_app, Repo,
      url: "ecto://postgres:postgres@localhost/ecto_simple?ssl=true&pool_size=10"

### IPv6 support

If your database's host resolves to ipv6 address you should
add `socket_options: [:inet6]` to configuration block like below:

    import Mix.Config

    config :my_app, MyApp.Repo,
      hostname: "db12.dc0.comp.any",
      socket_options: [:inet6],
      ...

## `use` options

When you `use Ecto.Repo`, the following options are supported:

  * `:otp_app` (required) - the name of the Erlang/OTP application
    to find your repository configuration (usually your Elixir app name)

  * `:adapter` (required) - the module of the database adapter you want to use

  * `:read_only` - when true, marks the repository as `:read_only`.
    In such cases, none of the functions that perform write operations, such as
    `c:insert/2`, `c:insert_all/3`, `c:update_all/3`, and friends are defined

## Shared options

Almost all of the repository functions outlined in this module accept the following
options:

  * `:timeout` - The time in milliseconds (as an integer) to wait for the query call to
    finish. `:infinity` will wait indefinitely (default: `15_000`)
  * `:log` - Can be any of the `Logger.level/0` values or `false`. If `false`,
    logging is disabled. Defaults to the configured Repo logger level
  * `:telemetry_event` - The telemetry event name to dispatch the event under.
    See the next section for more information
  * `:telemetry_options` - Extra options to attach to telemetry event name.
    See the next section for more information
  * `:query_cache` - When set to `false`, bypasses the Ecto query cache for the current
    operation. This means the query will not be looked up in the cache, it will not be stored
    in the cache and no cache update function will not be passed to the adapter. Note that
    this doesn't necessarily disable the database cache, it only affects Ecto's internal
    cache of normalized queries and adapter prepared statements. Defaults to `true`.

## Adapter-Specific Errors

Many of the functions in this module may raise adapter-specific errors, such as `PostgrexError`.
This can happen, for example, when the underlying database cannot execute the specified query.

## Telemetry events

There are two types of telemetry events. The ones emitted by Ecto and the
ones that are adapter specific.

### Ecto telemetry events

The following events are emitted by all Ecto repositories:

  * `[:ecto, :repo, :init]` - it is invoked whenever a repository starts.
    The measurement is a single `system_time` entry in native unit. The
    metadata is the `:repo` and all initialization options under `:opts`.

### Adapter-specific events

We recommend adapters to publish certain `Telemetry` events listed below.
Those events will use the `:telemetry_prefix` outlined above which defaults
to `[:my_app, :repo]`.

For instance, to receive all query events published by a repository called
`MyApp.Repo`, one would define a module:

    defmodule MyApp.Telemetry do
      def handle_event([:my_app, :repo, :query], measurements, metadata, config) do
        IO.inspect binding()
      end
    end

Then, in the `Application.start/2` callback, attach the handler to this event using
a unique handler id:

    :ok = :telemetry.attach("my-app-handler-id", [:my_app, :repo, :query], &MyApp.Telemetry.handle_event/4, %{})

For details, see [the telemetry documentation](https://hexdocs.pm/telemetry/).

Below we list all events developers should expect from Ecto. All examples
below consider a repository named `MyApp.Repo`:

#### `[:my_app, :repo, :query]`

This event should be invoked on every query sent to the adapter, including
queries that are related to the transaction management.

The `:measurements` map may include the following, all given in the
`:native` time unit:

  * `:idle_time` - the time the connection spent waiting before being checked out for the query
  * `:queue_time` - the time spent waiting to check out a database connection
  * `:query_time` - the time spent executing the query
  * `:decode_time` - the time spent decoding the data received from the database
  * `:total_time` - the sum of (`queue_time`, `query_time`, and `decode_time`)️

All measurements are given in the `:native` time unit. You can read more
about it in the docs for `System.convert_time_unit/3`.

A telemetry `:metadata` map including the following fields. Each database
adapter may emit different information here. For Ecto.SQL databases, it
will look like this:

  * `:type` - the type of the Ecto query. For example, for Ecto.SQL
    databases, it would be `:ecto_sql_query`
  * `:repo` - the Ecto repository
  * `:result` - the query result
  * `:params` - the dumped query parameters (formatted for database drivers like Postgrex)
  * `:cast_params` - the casted query parameters (normalized before dumping)
  * `:query` - the query sent to the database as a string
  * `:source` - the source the query was made on (may be `nil`)
  * `:stacktrace` - the stacktrace information, if enabled, or `nil`
  * `:options` - extra options given to the repo operation under
    `:telemetry_options`

## __using__/1

Returns all running Ecto repositories.

The list is returned in no particular order. The list
contains either atoms, for named Ecto repositories, or
PIDs.