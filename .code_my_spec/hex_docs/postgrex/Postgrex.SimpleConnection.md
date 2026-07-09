# Postgrex.SimpleConnection



## reply/2

Replies to the given client.

Wrapper for `:gen_statem.reply/2`.

## call/3

Calls the given server.

Wrapper for `:gen_statem.call/3`.

## start_link/3

Start the connection process and connect to Postgres.

The options that this function accepts are the same as those accepted by
`Postgrex.start_link/1`, as well as the extra options `:sync_connect`,
`:auto_reconnect`, `:reconnect_backoff`, and `:configure`.

## Options

  * `:auto_reconnect` - automatically attempt to reconnect to the database
    in event of a disconnection. Defaults to `false`, which means the process
    terminates. See the note in `Postgrex.Notifications` about [async connect
    and auto-reconnects][async-caveat].

  * `:configure` - A function to run before every connect attempt to dynamically
    configure the options as a `{module, function, args}`, where the current
    options will prepended to `args`. Defaults to `nil`.

  * `:idle_interval` - while also accepted on `Postgrex.start_link/1`, it has
    a default of `5000ms` in `Postgrex.SimpleConnection` (instead of 1000ms).

  * `:reconnect_backoff` - time (in ms) between reconnection attempts when
    `auto_reconnect` is enabled. Defaults to `500`.

  * `:sync_connect` - controls if the connection should be established on boot
    or asynchronously right after boot. Defaults to `true`.

[async-caveat]: Postgrex.Notifications.html#module-async-connect-auto-reconnects-and-missed-notifications