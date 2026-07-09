# Phoenix.Socket.Transport

Outlines the Socket <-> Transport communication.

Each transport, such as websockets and longpolling, must interact
with a socket. This module defines the functions a transport will
invoke on a given socket implementation.

`Phoenix.Socket` is just one possible implementation of a socket
that multiplexes events over multiple channels. If you implement
this behaviour, then existing transports can use your new socket
implementation, without passing through channels.

This module also provides guidelines and convenience functions for
implementing transports. Albeit its primary goal is to aid in the
definition of custom sockets.

## Example

Here is a simple echo socket implementation:

    defmodule EchoSocket do
      @behaviour Phoenix.Socket.Transport

      def child_spec(opts) do
        # We won't spawn any process, so let's ignore the child spec
        :ignore
      end

      def connect(state) do
        # Callback to retrieve relevant data from the connection.
        # The map contains options, params, transport and endpoint keys.
        {:ok, state}
      end

      def init(state) do
        # Now we are effectively inside the process that maintains the socket.
        {:ok, state}
      end

      def handle_in({text, _opts}, state) do
        {:reply, :ok, {:text, text}, state}
      end

      def handle_info(_, state) do
        {:ok, state}
      end

      def terminate(_reason, _state) do
        :ok
      end
    end

It can be mounted in your endpoint like any other socket:

    socket "/socket", EchoSocket, websocket: true, longpoll: true

You can now interact with the socket under `/socket/websocket`
and `/socket/longpoll`.

## Custom transports

Sockets are operated by a transport. When a transport is defined,
it usually receives a socket module and the module will be invoked
when certain events happen at the transport level. The functions
a transport can invoke are the callbacks defined in this module.

Whenever the transport receives a new connection, it should invoke
the `c:connect/1` callback with a map of metadata. Different sockets
may require different metadata.

If the connection is accepted, the transport can move the connection
to another process, if so desires, or keep using the same process. The
process responsible for managing the socket should then call `c:init/1`.

For each message received from the client, the transport must call
`c:handle_in/2` on the socket. For each informational message the
transport receives, it should call `c:handle_info/2` on the socket.

Transports can optionally implement `c:handle_control/2` for handling
control frames such as `:ping` and `:pong`.

On termination, `c:terminate/2` must be called. A special atom with
reason `:closed` can be used to specify that the client terminated
the connection.

### Booting

When you list a socket under `Phoenix.Endpoint.socket/3`, Phoenix
will automatically start the socket module under its supervision tree,
however Phoenix does not manage any transport.

Whenever your endpoint starts, Phoenix invokes the `child_spec/1` on
each listed socket and start that specification under the endpoint
supervisor. Since the socket supervision tree is started by the endpoint,
any custom transport must be started after the endpoint.

## load_config/2

Invoked on termination.

If `reason` is `:closed`, it means the client closed the socket. This is
considered a `:normal` exit signal, so linked process will not automatically
exit. See `Process.exit/2` for more details on exit signals.

## code_reload/3

Runs the code reloader if enabled.

## transport_log/2

Logs the transport request.

Available for transports that generate a connection.

## check_origin/5

Checks the origin request header against the list of allowed origins.

Should be called by transports before connecting when appropriate.
If the origin header matches the allowed origins, no origin header was
sent or no origin was configured, it will return the given connection.

Otherwise a 403 Forbidden response will be sent and the connection halted.
It is a noop if the connection has been halted.

## check_subprotocols/2

Checks the Websocket subprotocols request header against the allowed subprotocols.

Should be called by transports before connecting when appropriate.
If the sec-websocket-protocol header matches the allowed subprotocols,
it will put sec-websocket-protocol response header and return the given connection.
If no sec-websocket-protocol header was sent it will return the given connection.

Otherwise a 403 Forbidden response will be sent and the connection halted.
It is a noop if the connection has been halted.

## connect_info/4

Extracts connection information from `conn` and returns a map.

Keys are retrieved from the optional transport option `:connect_info`.
This functionality is transport specific. Please refer to your transports'
documentation for more information.

The supported keys are:

  * `:peer_data` - the result of `Plug.Conn.get_peer_data/1`

  * `:trace_context_headers` - a list of all trace context headers

  * `:x_headers` - a list of all request headers that have an "x-" prefix

  * `:uri` - a `%URI{}` derived from the conn

  * `:user_agent` - the value of the "user-agent" request header

  * `:sec_websocket_headers` - a list of all request headers that have a "sec-websocket-" prefix

The CSRF check can be disabled by setting the `:check_csrf` option to `false`.