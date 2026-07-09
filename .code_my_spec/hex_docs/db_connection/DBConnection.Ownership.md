# DBConnection.Ownership

A DBConnection pool that requires explicit checkout and checkin
as a mechanism to coordinate between processes.

## Options

  * `:ownership_mode` - When mode is `:manual`, all connections must
    be explicitly checked out before by using `ownership_checkout/2`.
    Otherwise, mode is `:auto` and connections are checked out
    implicitly. `{:shared, owner}` mode is also supported so
    processes are allowed on demand. On all cases, checkins are
    explicit via `ownership_checkin/2`. Defaults to `:auto`.
  * `:ownership_timeout` - The maximum time (in milliseconds) that a process
    is allowed to own a connection or `:infinity`, default `120_000`.
    This timeout exists mostly for sanity checking purposes and can be increased
    at will, since DBConnection automatically checks in connections whenever
    there is a mode change.
  * `:ownership_log` - The `Logger.level` to log ownership changes, or `nil`
    not to log, default `nil`.

There are also two experimental options, `:post_checkout` and `:pre_checkin`
which allows a developer to configure what happens when a connection is
checked out and checked in. Those options are meant to be used during tests,
and have the following behaviour:

  * `:post_checkout` - it must be an anonymous function that receives the
    connection module, the connection state and it must return either
    `{:ok, connection_module, connection_state}` or
    `{:disconnect, err, connection_module, connection_state}`. This allows
    the developer to change the connection module on post checkout. However,
    in case of disconnects, the return `connection_module` must be the same
    as the `connection_module` given. Defaults to simply returning the given
    connection module and state.

  * `:pre_checkin` - it must be an anonymous function that receives the
    checkin reason (`:checkin`, `{:disconnect, err}` or `{:stop, err}`),
    the connection module and the connection state returned by `post_checkout`.
    It must return either `{:ok, connection_module, connection_state}` or
    `{:disconnect, err, connection_module, connection_state}` where the connection
    module is the module given to `:post_checkout` Defaults to simply returning
    the given connection module and state.

## Callers lookup

When checking out, the ownership pool first looks if there is a connection
assigned to the current process and then checks if there is a connection
assigned to any of the processes listed under the `$callers` process
dictionary entry. The `$callers` entry is set by default for tasks from
Elixir v1.8.

You can also pass the `:caller` option on checkout with a pid and that
pid will be looked up first, instead of `self()`, and then we fall back
to `$callers`.

## ownership_checkout/2

Explicitly checks a connection out from the ownership manager.

It may return `:ok` if the connection is checked out.
`{:already, :owner | :allowed}` if the caller process already
has a connection, or raise if there was an error.