# Plug.Conn.Adapter

Specification of the connection adapter API implemented by webservers.

## Implementation recommendations

The `owner` field of `Plug.Conn` is deprecated and no longer needs to
be set by adapters. If you don't set the `owner` field, it is the
responsibility of the adapters to track the owner and send the
`already_sent/0` message below on any of the `send_*` callbacks.

## already_sent/0

The message to send to the request process on send callbacks.

## conn/5

Function used by adapters to create a new connection.