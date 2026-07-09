# NimblePool



## child_spec/1

Defines a pool to be started under the supervision tree.

It accepts the same options as `start_link/1` with the
addition or `:restart` and `:shutdown` that control the
"Child Specification".

## Examples

    NimblePool.child_spec(worker: {__MODULE__, :some_arg}, restart: :temporary)

## start_link/1

Starts a pool.

## Options

  * `:worker` - a `{worker_mod, worker_init_arg}` tuple with the worker
    module that implements the `NimblePool` behaviour and the worker
    initial argument. This argument is **required**.

  * `:pool_size` - how many workers in the pool. Defaults to `10`.

  * `:lazy` - When `true`, workers are started lazily, only when necessary.
    Defaults to `false`.

  * `:worker_idle_timeout` - Timeout in milliseconds to tag a worker as idle.
    If not nil, starts a periodic timer on the same frequency that will ping
    all idle workers using `handle_ping/2` optional callback .
    Defaults to no timeout.

  * `:max_idle_pings` - Defines a limit to the number of workers that can be pinged
    for each cycle of the `handle_ping/2` optional callback.
    Defaults to no limit. See `handle_ping/2` for more details.

## stop/3

Stops the given `pool`.

The pool exits with the given `reason`. The pool has `timeout` milliseconds
to terminate, otherwise it will be brutally terminated.

## Examples

    NimblePool.stop(pool)
    #=> :ok

## checkout!/4

Checks out a worker from the pool.

It expects a command, which will be passed to the `c:handle_checkout/4`
callback. The `c:handle_checkout/4` callback will return a client state,
which is given to the `function`.

The `function` receives two arguments, the request
(`{pid(), reference()}`) and the `client_state`.
The function must return a two-element tuple, where the first element is the
return value for `checkout!/4`, and the second element is the updated `client_state`,
which will be given as the first argument to `c:handle_checkin/4`.

`checkout!/4` also has an optional `timeout` value. This value will be applied
to the checkout operation itself. The "check in" operation happens asynchronously.

## update/2

Sends an **update** instruction to the pool about the checked out worker.

This must be called inside the `checkout!/4` callback function with
the `from` value given to `c:handle_checkout/4`.

This is useful to update the pool's state before effectively
checking the state in, which is handy when transferring
resources requires two steps.