# Mint.TransportError

Represents an error with the transport used by an HTTP connection.

A `Mint.TransportError` struct is an exception, so it can be raised as any
other exception.

## Struct fields

This exception represents an error with the transport (TCP or SSL) used
by an HTTP connection. The exception struct itself is opaque, that is,
not all fields are public. The following are the public fields:

  * `:reason` - a term representing the error reason. The value of this field
    can be:

      * `:timeout` - if there's a timeout in interacting with the socket.

      * `:closed` - if the connection has been closed.

      * `:protocol_not_negotiated` - if the ALPN protocol negotiation failed.

      * `{:bad_alpn_protocol, protocol}` - when the ALPN protocol is not
        one of the supported protocols, which are `http/1.1` and `h2`.

      * `t::inet.posix/0` - if there's any other error with the socket,
        such as `:econnrefused` or `:nxdomain`.

      * `t::ssl.error_alert/0` - if there's an SSL error.

## Message representation

If you want to convert an error reason to a human-friendly message (for example
for using in logs), you can use `Exception.message/1`:

    iex> {:error, %Mint.TransportError{} = error} = Mint.HTTP.connect(:http, "nonexistent", 80)
    iex> Exception.message(error)
    "non-existing domain"