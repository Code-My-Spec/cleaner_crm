# Mint.HTTP2

Process-less HTTP/2 client connection.

This module provides a data structure that represents an HTTP/2 connection to
a given server. The connection is represented as an opaque struct `%Mint.HTTP2{}`.
The connection is a data structure and is not backed by a process, and all the
connection handling happens in the process that creates the struct.

This module and data structure work exactly like the ones described in the `Mint.HTTP`
module, with the exception that `Mint.HTTP2` specifically deals with HTTP/2 while
`Mint.HTTP` deals seamlessly with HTTP/1.1 and HTTP/2. For more information on
how to use the data structure and client architecture, see `Mint.HTTP`.

## HTTP/2 Streams and Requests

HTTP/2 introduces the concept of **streams**. A stream is an isolated conversation
between the client and the server. Each stream is unique and identified by a unique
**stream ID**, which means that there's no order when data comes on different streams
since they can be identified uniquely. A stream closely corresponds to a request, so
in this documentation and client we will mostly refer to streams as "requests".
We mentioned data on streams can come in arbitrary order, and streams are requests,
so the practical effect of this is that performing request A and then request B
does not mean that the response to request A will come before the response to request B.
This is why we identify each request with a unique reference returned by `request/5`.
See `request/5` for more information.

## Closed Connection

In HTTP/2, the connection can either be open, closed, or only closed for writing.
When a connection is closed for writing, the client cannot send requests or stream
body chunks, but it can still read data that the server might be sending. When the
connection gets closed on the writing side, a `:server_closed_connection` error is
returned. `{:error, request_ref, error}` is returned for requests that haven't been
processed by the server, with the reason of `error` being `:unprocessed`.
These requests are safe to retry.

## HTTP/2 Settings

HTTP/2 supports settings negotiation between servers and clients. The server advertises
its settings to the client and the client advertises its settings to the server. A peer
(server or client) has to acknowledge the settings advertised by the other peer before
those settings come into action (that's why it's called a negotiation).

A first settings negotiation happens right when the connection starts.
Servers and clients can renegotiate settings at any time during the life of the
connection.

Mint users don't need to care about settings acknowledgements directly since they're
handled transparently by `stream/2`.

To retrieve the server settings, you can use `get_server_setting/2`. Doing so is often
useful to be able to tune your requests based on the server settings.

To communicate client settings to the server, use `put_settings/2` or pass them when
starting up a connection with `connect/4`. Note that the server needs to acknowledge
the settings sent through `put_setting/2` before those settings come into effect. The
server ack is processed transparently by `stream/2`, but this means that if you change
a setting through `put_settings/2` and try to retrieve the value of that setting right
after with `get_client_setting/2`, you'll likely get the old value of that setting. Once
the server acknowledges the new settings, the updated value will be returned by
`get_client_setting/2`.

## Server Push

HTTP/2 supports [server push](https://en.wikipedia.org/wiki/HTTP/2_Server_Push), which
is a way for a server to send a response to a client without the client needing to make
the corresponding request. The server sends a `:push_promise` response to a normal request:
this creates a new request reference. Then, the server sends normal responses for the newly
created request reference.

Let's see an example. We will ask the server for `"/index.html"` and the server will
send us a push promise for `"/style.css"`.

    {:ok, conn} = Mint.HTTP2.connect(:https, "example.com", 443)
    {:ok, conn, request_ref} = Mint.HTTP2.request(conn, "GET", "/index.html", _headers = [], _body = "")

    next_message =
      receive do
        msg -> msg
      end

    {:ok, conn, responses} = Mint.HTTP2.stream(conn, next_message)

    [
      {:push_promise, ^request_ref, promised_request_ref, promised_headers},
      {:status, ^request_ref, 200},
      {:headers, ^request_ref, []},
      {:data, ^request_ref, "<html>..."},
      {:done, ^request_ref}
    ] = responses

    promised_headers
    #=> [{":method", "GET"}, {":path", "/style.css"}]

As you can see in the example above, when the server sends a push promise then a
`:push_promise` response is returned as a response to a request. The `:push_promise`
response contains a `promised_request_ref` and some `promised_headers`. The
`promised_request_ref` is the new request ref that pushed responses will be tagged with.
`promised_headers` are headers that tell the client *what request* the promised response
will respond to. The idea is that the server tells the client a request the client will
want to make and then preemptively sends a response for that request. Promised headers
will always include `:method`, `:path`, and `:authority`.

    next_message =
      receive do
        msg -> msg
      end

    {:ok, conn, responses} = Mint.HTTP2.stream(conn, next_message)

    [
      {:status, ^promised_request_ref, 200},
      {:headers, ^promised_request_ref, []},
      {:data, ^promised_request_ref, "body { ... }"},
      {:done, ^promised_request_ref}
    ]

The response to a promised request is like a response to any normal request.

> #### Disabling Server Pushes {: .tip}
>
> HTTP/2 exposes a boolean setting for enabling or disabling server pushes with `:enable_push`.
> You can pass this option when connecting or in `put_settings/2`. By default server push
> is enabled.

## connect/4

Same as `Mint.HTTP.connect/4`, but forces a HTTP/2 connection.

## close/1

See `Mint.HTTP.close/1`.

## open?/2

See `Mint.HTTP.open?/1`.

## request/5

See `Mint.HTTP.request/5`.

In HTTP/2, opening a request means opening a new HTTP/2 stream (see the
module documentation). This means that a request could fail because the
maximum number of concurrent streams allowed by the server has been reached.
In that case, the error reason `:too_many_concurrent_requests` is returned.
If you want to avoid incurring in this error, you can retrieve the value of
the maximum number of concurrent streams supported by the server through
`get_server_setting/2` (passing in the `:max_concurrent_streams` setting name).

## Header list size

In HTTP/2, the server can optionally specify a maximum header list size that
the client needs to respect when sending headers. The header list size is calculated
by summing the length (in bytes) of each header name plus value, plus 32 bytes for
each header. Note that pseudo-headers (like `:path` or `:method`) count towards
this size. If the size is exceeded, an error is returned. To check what the size
is, use `get_server_setting/2`.

## Request body size

If the request body size will exceed the window size of the HTTP/2 stream created by the
request or the window size of the connection Mint will return a `:exceeds_window_size`
error.

To ensure you do not exceed the window size it is recommended to stream the request
body by initially passing `:stream` as the body and sending the body in chunks using
`stream_request_body/3` and using `get_window_size/2` to get the window size of the
request and connection.

## stream_request_body/3

See `Mint.HTTP.stream_request_body/3`.

## ping/2

Pings the server.

This function is specific to HTTP/2 connections. It sends a **ping** request to
the server `conn` is connected to. A `{:ok, conn, request_ref}` tuple is returned,
where `conn` is the updated connection and `request_ref` is a unique reference that
identifies this ping request. The response to a ping request is returned by `stream/2`
as a `{:pong, request_ref}` tuple. If there's an error, this function returns
`{:error, conn, reason}` where `conn` is the updated connection and `reason` is the
error reason.

`payload` must be an 8-byte binary with arbitrary content. When the server responds to
a ping request, it will use that same payload. By default, the payload is an 8-byte
binary with all bits set to `0`.

Pinging can be used to measure the latency with the server and to ensure the connection
is alive and well.

## Examples

    {:ok, conn, ref} = Mint.HTTP2.ping(conn)

## put_settings/2

Communicates the given **client settings** to the server.

This function is HTTP/2-specific.

This function takes a connection and a keyword list of HTTP/2 settings and sends
the values of those settings to the server. The settings won't be effective until
the server acknowledges them, which will be handled transparently by `stream/2`.

This function returns `{:ok, conn}` when sending the settings to the server is
successful, with `conn` being the updated connection. If there's an error, this
function returns `{:error, conn, reason}` with `conn` being the updated connection
and `reason` being the reason of the error.

## Supported Settings

See `t:setting/0` for the supported settings. You can see the meaning
of these settings [in the corresponding section in the HTTP/2
RFC](https://httpwg.org/specs/rfc7540.html#SettingValues).

See the "HTTP/2 settings" section in the module documentation for more information.

## Examples

    {:ok, conn} = Mint.HTTP2.put_settings(conn, max_frame_size: 100)

## get_server_setting/2

Gets the value of the given HTTP/2 server settings.

This function returns the value of the given HTTP/2 setting that the server
advertised to the client. This function is HTTP/2 specific.
For more information on HTTP/2 settings, see [the related section in
the RFC](https://httpwg.org/specs/rfc7540.html#SettingValues).

See the "HTTP/2 settings" section in the module documentation for more information.

## Supported settings

The possible settings that can be retrieved are described in `t:setting/0`.
Any other atom passed as `name` will raise an error.

## Examples

    Mint.HTTP2.get_server_setting(conn, :max_concurrent_streams)
    #=> 500

## get_client_setting/2

Gets the value of the given HTTP/2 client setting.

This function returns the value of the given HTTP/2 setting that the client
advertised to the server. Client settings can be advertised through `put_settings/2`
or when starting up a connection.

Client settings have to be acknowledged by the server before coming into effect.

This function is HTTP/2 specific. For more information on HTTP/2 settings, see
[the related section in the RFC](https://httpwg.org/specs/rfc7540.html#SettingValues).

See the "HTTP/2 settings" section in the module documentation for more information.

## Supported settings

The possible settings that can be retrieved are described in `t:setting/0`.
Any other atom passed as `name` will raise an error.

## Examples

    Mint.HTTP2.get_client_setting(conn, :max_concurrent_streams)
    #=> 500

## cancel_request/2

Cancels an in-flight request.

This function is HTTP/2 specific. It cancels an in-flight request. The server could have
already sent responses for the request you want to cancel: those responses will be parsed
by the connection but not returned to the user. No more responses
to a request will be returned after you call `cancel_request/2` on that request.

If there's no error in canceling the request, `{:ok, conn}` is returned where `conn` is
the updated connection. If there's an error, `{:error, conn, reason}` is returned where
`conn` is the updated connection and `reason` is the error reason.

## Examples

    {:ok, conn, ref} = Mint.HTTP2.request(conn, "GET", "/", _headers = [])
    {:ok, conn} = Mint.HTTP2.cancel_request(conn, ref)

## get_window_size/2

Returns the client **send** window size for the connection or a request.

> #### Send vs receive windows {: .warning}
>
> This function returns the *send* window — how much body data this client
> is still permitted to send to the server before being throttled. It is
> decremented by `request/5` and `stream_request_body/3` and refilled by
> the server, which `stream/2` handles transparently.
>
> It does **not** return the client *receive* window (how much the server
> is permitted to send us). To influence that, use `set_window_size/3`.

This function is HTTP/2 specific. It returns the send window of either the
connection if `connection_or_request` is `:connection` or of a single request
if `connection_or_request` is `{:request, request_ref}`.

Use this function to check the window size of the connection before sending a
full request. Also use this function to check the window size of both the
connection and of a request if you want to stream body chunks on that request.

For more information on flow control and window sizes in HTTP/2, see the section
below.

## HTTP/2 Flow Control

In HTTP/2, flow control is implemented through a window size. When the client
sends data to the server, the window size is decreased and the server needs
to "refill" it on the client side, which `stream/2` handles transparently.
Symmetrically, the server's outbound flow toward the client is bounded by a
receive window the client advertises and refills — see `set_window_size/3`.

A window size is kept for the entire connection and all requests affect this
window size. A window size is also kept per request.

The only thing that affects the send window size is the body of a request,
regardless of whether it's a full request sent with `request/5` or body chunks
sent through `stream_request_body/3`. That means that if we make a request with
a body that is five bytes long, like `"hello"`, the send window size of the
connection and the send window size of that particular request will decrease
by five bytes.

If we use all the send window size before the server refills it, functions like
`request/5` will return an error.

## Examples

On the connection:

    HTTP2.get_window_size(conn, :connection)
    #=> 65_536

On a single streamed request:

    {:ok, conn, request_ref} = HTTP2.request(conn, "GET", "/", [], :stream)
    HTTP2.get_window_size(conn, {:request, request_ref})
    #=> 65_536

    {:ok, conn} = HTTP2.stream_request_body(conn, request_ref, "hello")
    HTTP2.get_window_size(conn, {:request, request_ref})
    #=> 65_531

## set_window_size/3

Advertises a larger client **receive** window to the server.

> #### Receive vs send windows {: .warning}
>
> This function sets the *receive* window — the peak amount of body data
> the server is permitted to send us before being throttled. It does
> **not** set the *send* window (how much body data we're permitted to
> send to the server) — the server controls that. See `get_window_size/2`
> for the send window.

Without calling this, `stream/2` refills the receive window in small
increments as response body data is consumed. Each refill costs a
round-trip before the server can send more, so bulk throughput is capped
at roughly `window / RTT`; on higher-latency links the default 64 KB
window makes that cap well below the link bandwidth. Raising the window
removes those pauses and is the main HTTP/2 tuning knob for bulk or
highly parallel downloads.

Mint exposes the per-stream initial window as the `:initial_window_size`
client setting passed to `connect/4`, but there is no connection-level
equivalent — use this function for the connection window, and for any
per-stream adjustment after a request has started.

`connection_or_request` is `:connection` for the whole connection or
`{:request, request_ref}` for a single request. `new_size` must be in
`1..2_147_483_647`. Windows can only grow: `new_size` smaller than the
current receive window returns
`{:error, conn, %Mint.HTTPError{reason: :window_size_too_small}}`, and
`new_size` equal to the current window is a no-op.

For more information on flow control and window sizes in HTTP/2, see the
section below.

## HTTP/2 Flow Control

See `get_window_size/2` for a description of the client *send* window.
The client *receive* window is the symmetric bound on the server's
outbound flow: it starts at 64 KB for the connection and for each new
request, is decremented by response body bytes, and is refilled by
`stream/2` as the body is consumed. A window size is kept for the entire
connection and all responses affect this window size; a window size is
also kept per request.

This function raises the *advertised* receive window — the peak the
server is allowed to fill before pausing. It does not pre-allocate any
buffers; it only permits the server to send further ahead of the
client's reads.

## Examples

Bump the connection-level receive window right after connect so the server
can stream multi-MB bodies without flow-control pauses:

    {:ok, conn} = Mint.HTTP2.connect(:https, host, 443)
    {:ok, conn} = Mint.HTTP2.set_window_size(conn, :connection, 8_000_000)

Give one specific request a bigger window than the per-stream default:

    {:ok, conn, ref} = Mint.HTTP2.request(conn, "GET", "/huge", [], nil)
    {:ok, conn} = Mint.HTTP2.set_window_size(conn, {:request, ref}, 16_000_000)

## stream/2

See `Mint.HTTP.stream/2`.

## open_request_count/1

See `Mint.HTTP.open_request_count/1`.

In HTTP/2, the number of open requests is the number of requests **opened by the client**
that have not yet received a `:done` response. It's important to note that only
requests opened by the client (with `request/5`) count towards the number of open
requests, as requests opened from the server with server pushes (see the "Server push"
section in the module documentation) are not considered open requests. We do this because
clients might need to know how many open requests there are because the server limits
the number of concurrent requests the client can open. To know how many requests the client
can open, see `get_server_setting/2` with the `:max_concurrent_streams` setting.

## recv/3

See `Mint.HTTP.recv/3`.

## set_mode/2

See `Mint.HTTP.set_mode/2`.

## controlling_process/2

See `Mint.HTTP.controlling_process/2`.

## put_private/3

See `Mint.HTTP.put_private/3`.

## get_private/3

See `Mint.HTTP.get_private/3`.

## delete_private/2

See `Mint.HTTP.delete_private/2`.

## put_log/2

See `Mint.HTTP.put_log/2`.

## get_socket/1

See `Mint.HTTP.get_socket/1`.

## get_proxy_headers/1

See `Mint.HTTP.get_proxy_headers/1`.

## request_body_window/2

See `Mint.HTTP.request_body_window/2`.