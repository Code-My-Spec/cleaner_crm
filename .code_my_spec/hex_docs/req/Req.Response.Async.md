# Req.Response.Async

Asynchronous response body.

This is the `response.body` when making a request with `into: :self`, that is,
streaming response body chunks to the current process mailbox.

This struct implements the `Enumerable` protocol where each element is a body chunk received
from the current process mailbox. HTTP Trailer fields are ignored.

If the request is sent using HTTP/1, an extra process is spawned to consume messages from the
underlying socket. On both HTTP/1 and HTTP/2 the messages are sent to the current process as
soon as they arrive, as a firehose. If you wish to maximize request rate or have more control
over how messages are streamed, use `into: fun` or `into: collectable` instead.

**Note:** This feature is currently experimental and it may change in future releases.

## Examples

    iex> resp = Req.get!("https://reqbin.org/ndjson?delay=1000", into: :self)
    iex> resp.body
    #Req.Response.Async<...>
    iex> Enum.each(resp.body, &IO.puts/1)
    # {"id":0}
    # {"id":1}
    # {"id":2}
    :ok