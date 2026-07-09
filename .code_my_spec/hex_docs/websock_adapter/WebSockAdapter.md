# WebSockAdapter

Defines adapters to allow common Web Servers to serve applications via the `WebSock` API.
Also provides a consistent upgrade facility to upgrade `Plug.Conn` requests to `WebSock`
connections for supported servers.

## upgrade/4

Upgrades the provided `Plug.Conn` connection request to a `WebSock` connection using the
provided `WebSock` compliant module as a handler.

This function returns the passed `conn` set to an `:upgraded` state. If `early_validate_upgrade`
is set to true (as it is by default), the request is first examined to determine if it
represents a valid WebSocket upgrade. If errors are discovered in the request, a
`WebSockAdapter.UpgradeError` is raised containing information about the failure

The provided `state` value will be used as the argument for `c:WebSock.init/1` once the WebSocket
connection has been successfully negotiated.

The `opts` keyword list argument allows a number of options to be set on the WebSocket
connection. Not all options may be supported by the underlying HTTP server. Possible values are
as follows:

* `early_validate_upgrade`: A boolean indicating whether or not WebSockAdapter should attempt to
validate the WebSocket upgrade request before returning from this call. The underlying webserver
may still perform its own validation during the actual upgrade process, but since this occurs
after the `c:Plug.call/2` lifecycle it can be difficult to meaningfully handle failed upgrades.
Having WebSockAdapter do its own checks as part of this call helps to alleviate this. Defaults
to `true`
* `timeout`: The number of milliseconds to wait after no client data is received before
 closing the connection. Defaults to `60_000`
* `compress`: Whether or not to accept negotiation of a compression extension with the client.
 Defaults to `false`
* `max_frame_size`: The maximum frame size to accept, in octets. If a frame size larger than this
 is received the connection will be closed. Defaults to `10_000_000` (10MB)
* `fullsweep_after`: The maximum number of garbage collections before forcing a fullsweep of
 the WebSocket connection process. Setting this option requires OTP 24 or newer
* `max_heap_size`: The maximum size of the websocket process heap in words, or a configuration
  map. See `:erlang.max_heap_size()` for more info
* `validate_utf8`: Whether the server should verify that the payload of text and close frames is valid UTF-8.
  This is required by the protocol specification but in some cases it may be more interesting to disable it
  in order to save resources. Note that binary frames do not have this UTF-8 requirement and are what should be
  used under normal circumstances if necessary
* `active_n`: (Cowboy only) The number of packets Cowboy will request from the socket at once. This can be used to tweak
  the performance of the server. Higher values reduce the number of times Cowboy need to request more
  packets from the port driver at the expense of potentially higher memory being used.
  This option does not apply to Websocket over HTTP/2
* `deflate_options`: A keyword list of options to pass to the deflate library.
  See `Bandit` or `:cow_ws` documentation for more details