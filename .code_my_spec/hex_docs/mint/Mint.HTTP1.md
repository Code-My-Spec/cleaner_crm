# Mint.HTTP1

Process-less HTTP/1.1 client connection.

This module provides a data structure that represents an HTTP/1 or HTTP/1.1 connection to
a given server. The connection is represented as an opaque struct `%Mint.HTTP1{}`.
The connection is a data structure and is not backed by a process, and all the
connection handling happens in the process that creates the struct.

This module and data structure work exactly like the ones described in the `Mint`
module, with the exception that `Mint.HTTP1` specifically deals with HTTP/1 and HTTP/1.1 while
`Mint` deals seamlessly with HTTP/1, HTTP/1.1, and HTTP/2. For more information on
how to use the data structure and client architecture, see `Mint`.

## connect/4

Same as `Mint.HTTP.connect/4`, but forces an HTTP/1 or HTTP/1.1 connection.

This function doesn't support proxying.

## Additional Options

  * `:case_sensitive_headers` - (boolean) if set to `true` the case of the supplied
     headers in requests will be preserved. The default is to lowercase the headers
     because HTTP/1.1 header names are case-insensitive. *Available since v1.6.0*.
  * `:skip_target_validation` - (boolean) if set to `true` the target of a request
     will not be validated. You might want this if you deal with non standard-
     conforming URIs but need to preserve them. The default is to validate the request
     target. *Available since v1.7.0*.
  * `:optional_responses` - (list of atoms) a list of optional responses to return.
    Defaults to `[]`. The allowed values in the list are:
     * `:status_reason`: includes the
        [reason-phrase](https://datatracker.ietf.org/doc/html/rfc9112#name-status-line)
        for the status code if it is returned by the server in the status-line.
        This is only available for HTTP/1.1 connections. *Available since v1.8.0*.

## close/1

See `Mint.HTTP.close/1`.

## open?/2

See `Mint.HTTP.open?/1`.

## request/5

See `Mint.HTTP.request/5`.

In HTTP/1 and HTTP/1.1, you can't open a new request if you're streaming the body of
another request. If you try, an error will be returned.

## stream_request_body/3

See `Mint.HTTP.stream_request_body/3`.

In HTTP/1, sending an empty chunk is a no-op.

## Transfer encoding and content length

When streaming the request body, Mint cannot send a precalculated `content-length`
request header because it doesn't know the body that you'll stream. However, Mint
will transparently handle the presence of a `content-length` header using this logic:

  * if you specifically set a `content-length` header, then transfer encoding and
    making sure the content length is correct for what you'll stream is up to you.

  * if you specifically set the transfer encoding (`transfer-encoding` header)
    to `chunked`, then it's up to you to
    [properly encode chunks](https://en.wikipedia.org/wiki/Chunked_transfer_encoding).

  * if you don't set the transfer encoding to `chunked` and don't provide a
    `content-length` header, Mint will do implicit `chunked` transfer encoding
    (setting the `transfer-encoding` header appropriately) and will take care
    of properly encoding the chunks.

## stream/2

See `Mint.HTTP.stream/2`.

## recv/3

See `Mint.HTTP.recv/3`.

## set_mode/2

See `Mint.HTTP.set_mode/2`.

## controlling_process/2

See `Mint.HTTP.controlling_process/2`.

## open_request_count/1

See `Mint.HTTP.open_request_count/1`.

In HTTP/1, the number of open requests is the number of pipelined requests.

## put_private/3

See `Mint.HTTP.put_private/3`.

## get_private/3

See `Mint.HTTP.get_private/3`.

## delete_private/2

See `Mint.HTTP.delete_private/2`.

## get_socket/1

See `Mint.HTTP.get_socket/1`.

## put_log/2

See `Mint.HTTP.put_log/2`.

## get_proxy_headers/1

See `Mint.HTTP.get_proxy_headers/1`.

## request_body_window/2

See `Mint.HTTP.request_body_window/2`.