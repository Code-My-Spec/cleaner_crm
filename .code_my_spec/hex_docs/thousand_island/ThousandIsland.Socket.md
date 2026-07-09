# ThousandIsland.Socket

Encapsulates a client connection's underlying socket, providing a facility to
read, write, and otherwise manipulate a connection from a client.

## new/3

Creates a new socket struct based on the passed parameters.

This is normally called internally by `ThousandIsland.Handler` and does not need to be
called by implementations which are based on `ThousandIsland.Handler`

## handshake/1

Handshakes the underlying socket if it is required (as in the case of SSL sockets, for example).

This is normally called internally by `ThousandIsland.Handler` and does not need to be
called by implementations which are based on `ThousandIsland.Handler`

## upgrade/3

Upgrades the transport of the socket to use the specified transport module, performing any client
handshaking that may be required. The passed options are blindly passed through to the new
transport module.

This is normally called internally by `ThousandIsland.Handler` and does not need to be
called by implementations which are based on `ThousandIsland.Handler`

## recv/3

Returns available bytes on the given socket. Up to `length` bytes will be
returned (0 can be passed in to get the next 'available' bytes, typically the
next packet). If insufficient bytes are available, the function can wait `timeout`
milliseconds for data to arrive.

## send/2

Sends the given data (specified as a binary or an IO list) on the given socket.

## sendfile/4

Sends the contents of the given file based on the provided offset & length

## shutdown/2

Shuts down the socket in the given direction.

## close/1

Closes the given socket. Note that a socket is automatically closed when the handler
process which owns it terminates

## getopts/2

Gets the given flags on the socket

Errors are usually from :inet.posix(), however, SSL module defines return type as any()

## setopts/2

Sets the given flags on the socket

Errors are usually from :inet.posix(), however, SSL module defines return type as any()

## sockname/1

Returns information in the form of `t:ThousandIsland.Transport.socket_info()` about the local end of the socket.

## peername/1

Returns information in the form of `t:ThousandIsland.Transport.socket_info()` about the remote end of the socket.

## peercert/1

Returns information in the form of `t:public_key.der_encoded()` about the peer certificate of the socket.

## secure?/1

Returns whether or not this protocol is secure.

## getstat/1

Returns statistics about the connection.

## negotiated_protocol/1

Returns information about the protocol negotiated during transport handshaking (if any).

## connection_information/1

Returns information about the SSL connection info, if transport is SSL.

## telemetry_span/1

Returns the telemetry span representing the lifetime of this socket