# Postgrex.Notifications



## start_link/1

Start the notification connection process and connect to postgres.

The options that this function accepts are the same as those accepted by
`Postgrex.start_link/1`, as well as the extra options `:sync_connect`,
`:auto_reconnect`, `:reconnect_backoff`, and `:configure`.

## Options

  * `:sync_connect` - controls if the connection should be established on boot
    or asynchronously right after boot. Defaults to `true`.

  * `:auto_reconnect` - automatically attempt to reconnect to the database
    in event of a disconnection. See the
    [note about async connect and auto-reconnects](#module-async-connect-and-auto-reconnects)
    above. Defaults to `false`, which means the process terminates.

  * `:reconnect_backoff` - time (in ms) between reconnection attempts when
    `auto_reconnect` is enabled. Defaults to `500`.

  * `:idle_interval` - while also accepted on `Postgrex.start_link/1`, it has
    a default of `5000ms` in `Postgrex.Notifications` (instead of 1000ms).

  * `:configure` - A function to run before every connect attempt to dynamically
    configure the options as a `{module, function, args}`, where the current
    options will prepended to `args`. Defaults to `nil`.

## listen!/3

Listens to an asynchronous notification channel `channel`. See `listen/2`.

## unlisten!/3

Stops listening on the given channel by passing the reference returned from
`listen/2`.