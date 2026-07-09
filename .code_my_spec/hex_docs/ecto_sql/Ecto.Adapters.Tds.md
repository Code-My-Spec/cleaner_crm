# Ecto.Adapters.Tds

Adapter module for MSSQL Server using the TDS protocol.

## Options

Tds options split in different categories described
below. All options can be given via the repository
configuration.

### Connection options

  * `:hostname` - Server hostname
  * `:port` - Server port (default: 1433)
  * `:username` - Username
  * `:password` - User password
  * `:database` - the database to connect to
  * `:pool` - The connection pool module, may be set to `Ecto.Adapters.SQL.Sandbox`
  * `:ssl` - Set to true if ssl should be used (default: false)
  * `:ssl_opts` - A list of ssl options, see Erlang's `ssl` docs
  * `:show_sensitive_data_on_connection_error` - show connection data and
    configuration whenever there is an error attempting to connect to the
    database

We also recommend developers to consult the `Tds.start_link/1` documentation
for a complete list of all supported options for driver.

### Storage options

  * `:collation` - the database collation. Used during database creation but
    it is ignored later

If you need collation other than Latin1, add `tds_encoding` as dependency to
your project `mix.exs` file then amend `config/config.ex` by adding:

    config :tds, :text_encoder, Tds.Encoding

This should give you extended set of most encoding. For complete list check
`Tds.Encoding` [documentation](https://hexdocs.pm/tds_encoding).

### After connect flags

After connecting to MSSQL server, TDS will check if there are any flags set in
connection options that should affect connection session behaviour. All flags are
MSSQL standard *SET* options. The following flags are currently supported:

  * `:set_language` - sets session language (consult stored procedure output
     `exec sp_helplanguage` for valid values)
  * `:set_datefirst` - number in range 1..7
  * `:set_dateformat` - atom, one of `:mdy | :dmy | :ymd | :ydm | :myd | :dym`
  * `:set_deadlock_priority` - atom, one of `:low | :high | :normal | -10..10`
  * `:set_lock_timeout` - number in milliseconds > 0
  * `:set_remote_proc_transactions` - atom, one of `:on | :off`
  * `:set_implicit_transactions` - atom, one of `:on | :off`
  * `:set_allow_snapshot_isolation` - atom, one of `:on | :off`
     (required if `Repo.transaction(fn -> ... end, isolation_level: :snapshot)` is used)
  * `:set_read_committed_snapshot` - atom, one of `:on | :off`

## Limitations

### UUIDs

MSSQL server has slightly different binary storage format for UUIDs (`uniqueidentifier`).
If you use `:binary_id`, the proper choice is made. Otherwise you must use the `Tds.Ecto.UUID`
type. Avoid using `Ecto.UUID` since it may cause unpredictable application behaviour.

### SQL `Char`, `VarChar` and `Text` types

When working with binaries and strings,there are some limitations you should be aware of:

  - Strings that should be stored in mentioned sql types must be encoded to column
    codepage (defined in collation). If collation is different than database collation,
    it is not possible to store correct value into database since the connection
    respects the database collation. Ecto does not provide way to override parameter
    codepage.

  - If you need other than Latin1 or other than your database default collation, as
    mentioned in "Storage Options" section, then manually encode strings using
    `Tds.Encoding.encode/2` into desired codepage and then tag parameter as `:binary`.
    Please be aware that queries that use this approach in where clauses can be 10x slower
    due increased logical reads in database.

  - You can't store VarChar codepoints encoded in one collation/codepage to column that
    is encoded in different collation/codepage. You will always get wrong result. This is
    not adapter or driver limitation but rather how string encoding works for single byte
    encoded strings in MSSQL server. Don't be confused if you are always seeing latin1 chars,
    they are simply in each codepoint table.

In particular, if a field has the type `:text`, only raw binaries will be allowed.
To avoid above limitations always use `:string` (NVarChar) type for text if possible.
If you really need to use VarChar's column type, you can use the `Tds.Ecto.VarChar`
Ecto type.

### JSON support

Even though the adapter will convert `:map` fields into JSON back and forth,
actual value is stored in NVarChar column.

### Query hints and table hints

MSSQL supports both query hints and table hints: https://docs.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query

For Ecto compatibility, the query hints must be given via the `lock` option, and they
will be translated to MSSQL's "OPTION". If you need to pass multiple options, you
can separate them by comma:

    from query, lock: "HASH GROUP, FAST 10"

Table hints are specified as a list alongside a `from` or `join`:

    from query, hints: ["INDEX (IX_Employee_ManagerID)"]

The `:migration_lock` will be treated as a table hint and defaults to "UPDLOCK".

### Multi Repo calls in transactions

To avoid deadlocks in your app, we exposed `:isolation_level`  repo transaction option.
This will tell to SQL Server Transaction Manager how to begin transaction.
By default, if this option is omitted, isolation level is set to `:read_committed`.

Any attempt to manually set the transaction isolation via queries, such as

    Ecto.Adapter.SQL.query("SET TRANSACTION ISOLATION LEVEL XYZ")

will fail once explicit transaction is started using `c:Ecto.Repo.transaction/2`
and reset back to :read_committed.

There is `Ecto.Query.lock/3` function can help by setting it to `WITH(NOLOCK)`.
This should allow you to do eventually consistent reads and avoid locks on given
table if you don't need to write to database.

NOTE: after explicit transaction ends (commit or rollback) implicit transactions
will run as READ_COMMITTED.