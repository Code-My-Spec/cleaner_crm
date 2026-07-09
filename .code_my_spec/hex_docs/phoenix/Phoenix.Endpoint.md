# Phoenix.Endpoint



## __using__/1

Broadcasts a `msg` from the given `from` as `event` in the given `topic` within the current node.

## socket/3

Defines a websocket/longpoll mount-point for a `socket`.

It expects a `path`, a `socket` module, and a set of options.
The socket module is typically defined with `Phoenix.Socket`.

Both websocket and longpolling connections are supported out
of the box.

## Options

  * `:websocket` - controls the websocket configuration.
    Defaults to `true`. May be false or a keyword list
    of options. See ["Common configuration"](#socket/3-common-configuration)
    and ["WebSocket configuration"](#socket/3-websocket-configuration)
    for the whole list

  * `:longpoll` - controls the longpoll configuration.
    Defaults to `false`. May be true or a keyword list
    of options. See ["Common configuration"](#socket/3-common-configuration)
    and ["Longpoll configuration"](#socket/3-longpoll-configuration)
    for the whole list

  * `:drainer` - a keyword list or a custom MFA function returning a keyword list, for example:

        {MyAppWeb.Socket, :drainer_configuration, []}

    configuring how to drain sockets on application shutdown.
    The goal is to notify all channels (and
    LiveViews) clients to reconnect. The supported options are:

    * `:batch_size` - How many clients to notify at once in a given batch.
      Defaults to 10000.
    * `:batch_interval` - The amount of time in milliseconds given for a
      batch to terminate. Defaults to 2000ms.
    * `:shutdown` - The maximum amount of time in milliseconds allowed
      to drain all batches. Defaults to 30000ms.
    * `:log` - the log level for drain actions. Defaults the `:log` option
      passed to `use Phoenix.Socket` or `:info`. Set it to `false` to disable logging.

    For example, if you have 150k connections, the default values will
    split them into 15 batches of 10k connections. Each batch takes
    2000ms before the next batch starts. In this case, we will do everything
    right under the maximum shutdown time of 30000ms. Therefore, as
    you increase the number of connections, remember to adjust the shutdown
    accordingly. Finally, after the socket drainer runs, the lower level
    HTTP/HTTPS connection drainer will still run, and apply to all connections.
    Set it to `false` to disable draining.

  * `auth_token` - a boolean that enables the use of the channels client's auth_token option.
    The exact token exchange mechanism depends on the transport:

      * the websocket transport, this enables a token to be passed through the `Sec-WebSocket-Protocol` header.
      * the longpoll transport, this allows the token to be passed through the `Authorization` header.

    The token is available in the `connect_info` as `:auth_token`.

    Custom transports might implement their own mechanism.

You can also pass the options below on `use Phoenix.Socket`.
The values specified here override the value in `use Phoenix.Socket`.

## Examples

    socket "/ws", MyApp.UserSocket

    socket "/ws/admin", MyApp.AdminUserSocket,
      longpoll: true,
      websocket: [compress: true]

## Path params

It is possible to include variables in the path, these will be
available in the `params` that are passed to the socket.

    socket "/ws/:user_id", MyApp.UserSocket,
      websocket: [path: "/project/:project_id"]

## Common configuration

The configuration below can be given to both `:websocket` and
`:longpoll` keys:

  * `:path` - the path to use for the transport. Will default
     to the transport name ("/websocket" or "/longpoll")

  * `:serializer` - a list of serializers for messages. See
    `Phoenix.Socket` for more information

  * `:transport_log` - if the transport layer itself should log and,
    if so, the level

  * `:check_origin` - if the transport should check the origin of requests when
    the `origin` header is present. May be `true`, `false`, a list of URIs that
    are allowed, or a function provided as MFA tuple. Defaults to `:check_origin`
    setting at endpoint configuration.

    If `true`, the header is checked against `:host` in `YourAppWeb.Endpoint.config(:url)[:host]`.

    If `false` and you do not validate the session in your socket, your app
    is vulnerable to Cross-Site WebSocket Hijacking (CSWSH) attacks.
    Only use in development, when the host is truly unknown or when
    serving clients that do not send the `origin` header, such as mobile apps.

    You can also specify a list of explicitly allowed origins. Each origin may include
    scheme, host, and port. Wildcards are supported.

        check_origin: [
          "https://example.com",
          "//another.com:888",
          "//*.other.com"
        ]

    Or to accept any origin matching the request connection's host, port, and scheme:

        check_origin: :conn

    Or a custom MFA function:

        check_origin: {MyAppWeb.Auth, :my_check_origin?, []}

    The MFA is invoked with the request `%URI{}` as the first argument,
    followed by arguments in the MFA list, and must return a boolean.

  * `:check_csrf` - if the transport should perform CSRF check. To avoid
    "Cross-Site WebSocket Hijacking", you must have at least one of
    `check_origin` and `check_csrf` enabled. If you set both to `false`,
    Phoenix will raise, but it is still possible to disable both by passing
    a custom MFA to `check_origin`. In such cases, it is your responsibility
    to ensure at least one of them is enabled. Defaults to `true`

  * `:code_reloader` - enable or disable the code reloader. Defaults to your
    endpoint configuration

  * `:connect_info` - a list of keys that represent data to be copied from
    the transport to be made available in the user socket `connect/3` callback.
    See the "Connect info" subsection for valid keys

### Connect info

The valid keys are:

  * `:peer_data` - the result of `Plug.Conn.get_peer_data/1`

  * `:trace_context_headers` - a list of all trace context headers. Supported
    headers are defined by the [W3C Trace Context Specification](https://www.w3.org/TR/trace-context-1/).
    These headers are necessary for libraries such as [OpenTelemetry](https://opentelemetry.io/)
    to extract trace propagation information to know this request is part of a
    larger trace in progress.

  * `:x_headers` - all request headers that have an "x-" prefix

  * `:uri` - a `%URI{}` with information from the conn

  * `:user_agent` - the value of the "user-agent" request header

  * `{:session, session_config}` - the session information from `Plug.Conn`.
    The `session_config` is typically an exact copy of the arguments given
    to `Plug.Session`. In order to validate the session, the "_csrf_token"
    must be given as request parameter when connecting the socket with the
    value of `URI.encode_www_form(Plug.CSRFProtection.get_csrf_token())`.
    The CSRF token request parameter can be modified via the `:csrf_token_key`
    option.

    Additionally, `session_config` may be a MFA, such as
    `{MyAppWeb.Auth, :get_session_config, []}`, to allow loading config in
    runtime.

Arbitrary keywords may also appear following the above valid keys, which
is useful for passing custom connection information to the socket.

For example:

```
  socket "/socket", AppWeb.UserSocket,
      websocket: [
        connect_info: [:peer_data, :trace_context_headers, :x_headers, :uri, session: [store: :cookie]]
      ]
```

With arbitrary keywords:

```
  socket "/socket", AppWeb.UserSocket,
      websocket: [
        connect_info: [:uri, custom_value: "abcdef"]
      ]
```

> #### Where are my headers? {: .tip}
>
> Phoenix only gives you limited access to the connection headers for security
> reasons. WebSockets are cross-domain, which means that, when a user "John Doe"
> visits a malicious website, the malicious website can open up a WebSocket
> connection to your application, and the browser will gladly submit John Doe's
> authentication/cookie information. If you were to accept this information as is,
> the malicious website would have full control of a WebSocket connection to your
> application, authenticated on John Doe's behalf.
>
> To safe-guard your application, Phoenix limits and validates the connection
> information your socket can access. This means your application is safe from
> these attacks, but you can't access cookies and other headers in your socket.
> You may access the session stored in the connection via the `:connect_info`
> option, provided you also pass a csrf token when connecting over WebSocket.

## Websocket configuration

The following configuration applies only to `:websocket`.

  * `:timeout` - the timeout for keeping websocket connections
    open after it last received data, defaults to 60_000ms

  * `:max_frame_size` - the maximum allowed frame size in bytes,
    defaults to "infinity"

  * `:fullsweep_after` - the maximum number of garbage collections
    before forcing a fullsweep for the socket process. You can set
    it to `0` to force more frequent cleanups of your websocket
    transport processes. Setting this option requires Erlang/OTP 24

  * `:compress` - whether to enable per message compression on
    all data frames, defaults to false

  * `:subprotocols` - a list of supported websocket subprotocols.
    Used for handshake `Sec-WebSocket-Protocol` response header, defaults to nil.

    For example:

        subprotocols: ["sip", "mqtt"]

  * `:error_handler` - custom error handler for connection errors.
    If `c:Phoenix.Socket.connect/3` returns an `{:error, reason}` tuple,
    the error handler will be called with the error reason. For WebSockets,
    the error handler must be a MFA tuple that receives a `Plug.Conn`, the
    error reason, and returns a `Plug.Conn` with a response. For example:

        socket "/socket", MySocket,
            websocket: [
              error_handler: {MySocket, :handle_error, []}
            ]

    and a `{:error, :rate_limit}` return may be handled on `MySocket` as:

        def handle_error(conn, :rate_limit), do: Plug.Conn.send_resp(conn, 429, "Too many requests")

## Longpoll configuration

The following configuration applies only to `:longpoll`:

  * `:window_ms` - how long the client can wait for new messages
    in its poll request in milliseconds (ms). Defaults to `10_000`.

  * `:pubsub_timeout_ms` - how long a request can wait for the
    pubsub layer to respond in milliseconds (ms). Defaults to `2000`.

  * `:crypto` - options for verifying and signing the token, accepted
    by `Phoenix.Token`. By default tokens are valid for 2 weeks

## server?/2

Checks if Endpoint's web server has been configured to start.

  * `otp_app` - The OTP app running the endpoint, for example `:my_app`
  * `endpoint` - The endpoint module, for example `MyAppWeb.Endpoint`

## Examples

    iex> Phoenix.Endpoint.server?(:my_app, MyAppWeb.Endpoint)
    true