# Ecto.Adapters.Postgres

Adapter module for PostgreSQL.

It uses `Postgrex` for communicating to the database.

## Features

  * Full query support (including joins, preloads and associations)
  * Support for transactions
  * Support for data migrations
  * Support for ecto.create and ecto.drop operations
  * Support for transactional tests via `Ecto.Adapters.SQL`

## Options

Postgres options split in different categories described
below. All options can be given via the repository
configuration:

    config :your_app, YourApp.Repo,
      ...

The `:prepare` option may be specified per operation:

    YourApp.Repo.all(Queryable, prepare: :unnamed)

### Migration options

  * `:migration_lock` - prevent multiple nodes from running migrations at the same
    time by obtaining a lock. The value `:table_lock` will lock migrations by wrapping
    the entire migration inside a database transaction, including inserting the
    migration version into the migration source (by default, "schema_migrations").
    You may alternatively select `:pg_advisory_lock` which has the benefit
    of allowing concurrent operations such as creating indexes. (default: `:table_lock`)

When using the `:pg_advisory_lock` migration lock strategy and Ecto cannot obtain
the lock due to another instance occupying the lock, Ecto will wait for 5 seconds
and then retry infinity times. This is configurable on the repo with keys
`:migration_advisory_lock_retry_interval_ms` and `:migration_advisory_lock_max_tries`.
If the retries are exhausted, the migration will fail.

Some downsides to using advisory locks is that some Postgres-compatible systems or plugins
may not support session level locks well and therefore result in inconsistent behavior.
For example, PgBouncer when using pool_modes other than session won't work well with
advisory locks. CockroachDB is another system that is designed in a way that advisory
locks don't make sense for their distributed database.

### Connection options

  * `:hostname` - Server hostname
  * `:socket_dir` - Connect to Postgres via UNIX sockets in the given directory
    The socket name is derived based on the port. This is the preferred method
    for configuring sockets and it takes precedence over the hostname. If you are
    connecting to a socket outside of the Postgres convention, use `:socket` instead;
  * `:socket` - Connect to Postgres via UNIX sockets in the given path.
    This option takes precedence over the `:hostname` and `:socket_dir`
  * `:username` - Username
  * `:password` - User password
  * `:port` - Server port (default: 5432)
  * `:database` - the database to connect to
  * `:maintenance_database` - Specifies the name of the database to connect to when
    creating or dropping the database. Defaults to `"postgres"`
  * `:pool` - The connection pool module, may be set to `Ecto.Adapters.SQL.Sandbox`
  * `:ssl` - Accepts a list of options to enable TLS for the client connection,
    or `false` to disable it. See the documentation for [Erlang's `ssl` module](`e:ssl:ssl`)
    for a list of options (default: false)
  * `:parameters` - Keyword list of connection parameters
  * `:connect_timeout` - The timeout for establishing new connections (default: 5000)
  * `:prepare` - How to prepare queries, either `:named` to use named queries
    or `:unnamed` to force unnamed queries (default: `:named`)
  * `:socket_options` - Specifies socket configuration
  * `:show_sensitive_data_on_connection_error` - show connection data and
    configuration whenever there is an error attempting to connect to the
    database

The `:socket_options` are particularly useful when configuring the size
of both send and receive buffers. For example, when Ecto starts with a
pool of 20 connections, the memory usage may quickly grow from 20MB to
50MB based on the operating system default values for TCP buffers. It is
advised to stick with the operating system defaults but they can be
tweaked if desired:

    socket_options: [recbuf: 8192, sndbuf: 8192]

We also recommend developers to consult the `Postgrex.start_link/1`
documentation for a complete listing of all supported options.

### Storage options

  * `:encoding` - the database encoding (default: "UTF8")
    or `:unspecified` to remove encoding parameter (alternative engine compatibility)
  * `:template` - the template to create the database from
  * `:lc_collate` - the collation order
  * `:lc_ctype` - the character classification
  * `:dump_path` - where to place dumped structures
  * `:dump_prefixes` - list of prefixes that will be included in the structure dump.
    When specified, the prefixes will have their definitions dumped along with the
    data in their migration table. When it is not specified, the configured
    database has the definitions dumped from all of its schemas but only
    the data from the migration table from the `public` schema is included.
  * `:force_drop` - force the database to be dropped even
    if it has connections to it (requires PostgreSQL 13+)

### After connect callback

If you want to execute a callback as soon as connection is established
to the database, you can use the `:after_connect` configuration. For
example, in your repository configuration you can add:

    after_connect: {Postgrex, :query!, ["SET search_path TO global_prefix", []]}

You can also specify your own module that will receive the Postgrex
connection as argument.

## Extensions

Both PostgreSQL and its adapter for Elixir, Postgrex, support an
extension system. If you want to use custom extensions for Postgrex
alongside Ecto, you must define a type module with your extensions.
Create a new file anywhere in your application with the following:

    Postgrex.Types.define(MyApp.PostgresTypes, [MyExtension.Foo, MyExtensionBar])

Once your type module is defined, you can configure the repository to use it:

    config :my_app, MyApp.Repo, types: MyApp.PostgresTypes

## Unix socket connection

You may desire to communicate with Postgres via Unix sockets.
If your PG server is started on the same machine as your code, you could check that:

```bash
% sudo grep unix_socket_directories /var/lib/postgres/data/postgresql.conf
unix_socket_directories = '/run/postgresql'
```

```bash
% ls -lah /run/postgresql
итого 4,0K
drwxr-xr-x  2 postgres postgres  80 июн  4 10:58 .
drwxr-xr-x 35 root     root     840 июн  4 21:02 ..
srwxrwxrwx  1 postgres postgres   0 июн  5 07:41 .s.PGSQL.5432
-rw-------  1 postgres postgres  61 июн  5 07:41 .s.PGSQL.5432.lock
```

So you have postgresql started and listening on the socket.
Then you may use it as follows:

    config :your_app, YourApp.Repo,
      socket_dir: "/run/postgresql"

## extensions/0

All Ecto extensions for Postgrex.

Currently Ecto does not define any of its own extensions for Postgrex.
If this changes in a future release, you will need to call this function
when defining your own custom extensions:

    Postgrex.Types.define(MyApp.PostgresTypes,
                          [MyExtension.Foo, MyExtensionBar] ++ Ecto.Adapters.Postgres.extensions())