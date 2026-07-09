# Ecto.Adapters.MyXQL

Adapter module for MySQL.

It uses `MyXQL` for communicating to the database.

## Options

MySQL options split in different categories described
below. All options can be given via the repository
configuration:

    config :your_app, YourApp.Repo,
      ...

The `:prepare` option may be specified per operation:

    YourApp.Repo.all(Queryable, prepare: :unnamed)

### Connection options

  * `:protocol` - Set to `:socket` for using UNIX domain socket, or `:tcp` for TCP
    (default: `:socket`)
  * `:socket` - Connect to MySQL via UNIX sockets in the given path.
  * `:hostname` - Server hostname
  * `:port` - Server port (default: 3306)
  * `:username` - Username
  * `:password` - User password
  * `:database` - the database to connect to
  * `:pool` - The connection pool module, may be set to `Ecto.Adapters.SQL.Sandbox`
  * `:ssl` - Accepts a list of options to enable TLS for the client connection,
    or `false` to disable it. See the documentation for [Erlang's `ssl` module](`e:ssl:ssl`)
    for a list of options (default: false)
  * `:connect_timeout` - The timeout for establishing new connections (default: 5000)
  * `:cli_protocol` - The protocol used for the mysql client connection (default: `"tcp"`).
    This option is only used for `mix ecto.load` and `mix ecto.dump`,
    via the `mysql` command. For more information, please check
    [MySQL docs](https://dev.mysql.com/doc/en/connecting.html)
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

We also recommend developers to consult the `MyXQL.start_link/1` documentation
for a complete listing of all supported options.

### Storage options

  * `:charset` - the database encoding (default: "utf8mb4")
  * `:collation` - the collation order
  * `:dump_path` - where to place dumped structures
  * `:dump_prefixes` - list of prefixes that will be included in the
    structure dump. For MySQL, this list must be of length 1. Multiple
    prefixes are not supported. When specified, the prefixes will have
    their definitions dumped along with the data in their migration table.
    When it is not specified, only the configured database and its migration
    table are dumped.

### After connect callback

If you want to execute a callback as soon as connection is established
to the database, you can use the `:after_connect` configuration. For
example, in your repository configuration you can add:

    after_connect: {MyXQL, :query!, ["SET variable = value", []]}

You can also specify your own module that will receive the MyXQL
connection as argument.

## Limitations

There are some limitations when using Ecto with MySQL that one
needs to be aware of.

### Engine

Tables created by Ecto are guaranteed to use InnoDB, regardless
of the MySQL version.

### UUIDs

MySQL does not support UUID types. Ecto emulates them by using
`binary(16)`.

### Read after writes

Because MySQL does not support RETURNING clauses in INSERT and
UPDATE, it does not support the `:read_after_writes` option of
`Ecto.Schema.field/3`.

### DDL Transaction

MySQL does not support migrations inside transactions as it
automatically commits after some commands like CREATE TABLE.
Therefore MySQL migrations does not run inside transactions.

### Insert Mode

The `:insert_mode` option controls the type of INSERT statement generated.
When set to `:ignore`, the adapter uses MySQL's `INSERT IGNORE`
syntax:

    Repo.insert_all(Post, posts, insert_mode: :ignore)

With `INSERT IGNORE`, MySQL silently ignores errors that would normally
cause the statement to fail, such as duplicate key violations and certain
type conversion errors. When a row is ignored, the affected row count
will be 0 instead of 1.

See [MySQL documentation](https://dev.mysql.com/doc/refman/8.4/en/insert.html) for more details.

### Upserts

When using `on_conflict: :nothing`, the adapter uses the
`ON DUPLICATE KEY UPDATE x = x` workaround to simulate "do nothing"
behavior. This always reports 1 affected row regardless of whether
the row was actually inserted or ignored.

If you need accurate row counts (0 when ignored, 1 when inserted) at the expense of error handling,
you can combine `on_conflict: :nothing` with [`insert_mode: :ignore`](#module-insert-mode):

    Repo.insert_all(Post, posts,
      on_conflict: :nothing,
      insert_mode: :ignore)

When both options are used together, `INSERT IGNORE` handles the conflict
resolution and the `ON DUPLICATE KEY UPDATE` clause is omitted.

Examples:

```elixir
Repo.insert_all(Post, posts,
  on_conflict: :nothing)

# SQL: INSERT INTO `posts` (`title`, `uuid`) VALUES (?,?) ON DUPLICATE KEY UPDATE `id` = VALUES(`id`)
```

```elixir
Repo.insert_all(Post, posts,
  on_conflict: :nothing,
  insert_mode: :ignore)

# SQL: INSERT IGNORE INTO `posts` (`title`, `uuid`) VALUES (?,?)
```

## Old MySQL versions

### JSON support

MySQL introduced a native JSON type in v5.7.8, if your server is
using this version or higher, you may use `:map` type for your
column in migration:

    add :some_field, :map

If you're using older server versions, use a `TEXT` field instead:

    add :some_field, :text

in either case, the adapter will automatically encode/decode the
value from JSON.

### usec in datetime

Old MySQL versions did not support usec in datetime while
more recent versions would round or truncate the usec value.

Therefore, in case the user decides to use microseconds in
datetimes and timestamps with MySQL, be aware of such
differences and consult the documentation for your MySQL
version.

If your version of MySQL supports microsecond precision, you
will be able to utilize Ecto's usec types.

## Multiple Result Support

MyXQL supports the execution of queries that return multiple
results, such as text queries with multiple statements separated
by semicolons or stored procedures. These can be executed with
`Ecto.Adapters.SQL.query_many/4` or the `YourRepo.query_many/3`
shortcut.

Be default, these queries will be executed with the `:query_type`
option set to `:text`. To take advantage of prepared statements
when executing a stored procedure, set the `:query_type` option
to `:binary`.