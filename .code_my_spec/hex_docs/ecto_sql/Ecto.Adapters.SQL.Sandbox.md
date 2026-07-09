# Ecto.Adapters.SQL.Sandbox



## start_owner!/2

Starts a process that will check out and own a connection, then returns that process's pid.

The process is not linked to the caller, so it is your responsibility to ensure that it will be
stopped with `stop_owner/1`. In tests, this is done in  an `ExUnit.Callbacks.on_exit/2` callback:

    setup tags do
      pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
      on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
      :ok
    end

## `start_owner!/2` vs `checkout/2`

`start_owner!/2` should be used in place of `checkout/2`.

`start_owner!/2` solves the problem of unlinked processes started in a test outliving the test process and causing ownership errors.
For example, `LiveView`'s `live(...)` test helper starts a process linked to the LiveView supervisor, not the test process.
These errors can be eliminated by having the owner of the connection be a separate process from the test process.

Outside of that scenario, `checkout/2` involves less overhead than this function and so can be preferable.

## Options

  * `:shared` - if `true`, the pool runs in the shared mode. Defaults to `false`

The remaining options are passed to `checkout/2`.

## stop_owner/1

Stops an owner process started by `start_owner!/2`.

## mode/2

Sets the mode for the `repo` pool.

The modes can be:

  * `:auto` - this is the default mode. When trying to use the repository,
    processes can automatically checkout a connection without calling
    `checkout/2` or `start_owner/2` before. This is the mode you will run
    on before your test suite starts

  * `:manual` - in this mode, the connection always has to be explicitly
    checked before used. Other processes are allowed to use the same
    connection if they are explicitly allowed via `allow/4`. You usually
    set the mode to manual at the end of your `test/test_helper.exs` file.
    This is also the mode you will run your async tests in

  * `{:shared, pid}` - after checking out a connection in manual mode,
    you can change the mode to `{:shared, pid}`, where pid is the process
    that owns the connection, most often `{:shared, self()}`. This makes it
    so all processes can use the same connection as the one owned by the
    current process. This is the mode you will run your sync tests in

Whenever you change the mode to `:manual` or `:auto`, all existing
connections are checked in. Therefore, it is recommend to set those
modes before your test suite starts, as otherwise you will check in
connections being used in any other test running concurrently.

If successful, returns `:ok` (this is always successful for `:auto`
and `:manual` modes). It may return `:not_owner` or `:not_found`
when setting `{:shared, pid}` and the given `pid` does not own any
connection for the repo. May return `:already_shared` if another
process set the ownership mode to `{:shared, _}` and is still alive.

## checkout/2

Checks a connection out for the given `repo`.

The process calling `checkout/2` will own the connection
until it calls `checkin/2` or until it crashes in which case
the connection will be automatically reclaimed by the pool.

If successful, returns `:ok`. If the caller already has a
connection, it returns `{:already, :owner | :allowed}`.

## Options

  * `:sandbox` - when true the connection is wrapped in
    a transaction. Defaults to true.

  * `:isolation` - set the query to the given isolation level.

  * `:ownership_timeout` - limits how long the connection can be
    owned. Defaults to the value in your repo config in
    `config/config.exs` (or preferably in `config/test.exs`), or
    120000 ms if not set. The timeout exists for sanity checking
    purposes, to ensure there is no connection leakage, and can
    be bumped whenever necessary.

## checkin/2

Checks in the connection back into the sandbox pool.

## allow/4

Allows the `allow` process to use the same connection as `parent`.

`allow` may be a PID or a locally registered name.

If the allowance is successful, this function returns `:ok`. If `allow` is already an
owner or already allowed, it returns `{:already, :owner | :allowed}`. If `parent` has not
checked out a connection from the repo, it returns `:not_found`.

## unboxed_run/2

Runs a function outside of the sandbox.