# Finch



## start_link/1

A guard that returns true if `ref` is a valid request reference from `async_request/3`.

Use this guard when matching on async response messages in `c:GenServer.handle_info/2`
so your code remains valid if the internal structure of the reference changes.

## Example

    require Finch

    def handle_info({ref, response}, state) when Finch.is_request_ref(ref) do
      # handle async response from Finch.async_request/3
    end

## find_pool/2

Finds a pool by its configuration and returns the pool pid.

Returns `{:ok, pid}` if the pool exists, `:error` otherwise.

This is useful for checking if a pool is available before making requests,
or for advanced use cases where you need direct access to the pool process.

## Example

    case Finch.find_pool(MyFinch, Finch.Pool.new("https://api.internal", tag: :api)) do
      {:ok, pid} -> # Pool exists
      :error -> # Pool not found
    end

## start_pool/3

Starts a pool dynamically under Finch's internal supervision tree.

Returns `:ok` if the pool was started or already exists.

## Options

Same pool configuration options as `Finch.start_link/1`:
`:size`, `:count`, `:protocols`, `:conn_opts`, etc.

## Example

    Finch.start_pool(MyFinch, Finch.Pool.new("https://api.example.com", tag: :api), size: 10)

## stream/5

Streams an HTTP request and returns the accumulator.

`resp_fun` receives a response entry and the accumulator `acc`, and must return
the updated accumulator.

Response entries are:

  * `{:status, status}` - the HTTP response status

  * `{:headers, headers}` - the HTTP response headers

  * `{:data, data}` - the HTTP response body chunk

  * `{:trailers, trailers}` - the HTTP response trailers

See also `request/3`, `stream_while/5`.

> ### HTTP2 streaming and back-pressure {: .warning}
>
> At the moment, streaming over HTTP2 connections do not provide
> any back-pressure mechanism: this means the response will be
> sent to the client as quickly as possible. Therefore, you must
> not use streaming over HTTP2 for non-terminating responses or
> when streaming large responses which you do not intend to keep
> in memory.

> ### Connection draining {: .info}
>
> If the HTTP/2 pool this request is dispatched to is currently draining (see
> `http2: [max_connection_age: ...]`), the request is automatically retried on a fresh
> pool. The retry is transparent to the caller. See `async_request/3` for the async
> variant, which does not retry automatically.

## Options

Shares options with `request/3`.

## Examples

    path = "/tmp/archive.zip"
    file = File.open!(path, [:write, :exclusive])
    url = "https://example.com/archive.zip"
    request = Finch.build(:get, url)

    Finch.stream(request, MyFinch, nil, fn
      {:status, status}, _acc ->
        IO.inspect(status)

      {:headers, headers}, _acc ->
        IO.inspect(headers)

      {:data, data}, _acc ->
        IO.binwrite(file, data)
    end)

    File.close(file)

## stream_while/5

Streams an HTTP request until it finishes or is cancelled.

## Request body streaming

When the request body is set to `{:stream, req_body_fun}` (see `build/5`), `req_body_fun`
receives the accumulator `acc` and must return one of:

  * `{:data, chunk, acc}` - emit request body `chunk` and continue streaming

  * `{:done, acc}` - request body is done, `acc` is passed to `resp_fun`

  * `{:halt, acc}` - cancel the request and close the connection

`{:stream, req_body_fun}` is currently only supported on HTTP/1 pools.

## Response streaming

`resp_fun` receives a response entry and the accumulator `acc`, and must return one of:

  * `{:cont, acc}` - continue streaming

  * `{:halt, acc}` - cancel the request. On HTTP/1, this also closes the connection

Response entries are:

  * `{:status, status}` - the HTTP response status

  * `{:headers, headers}` - the HTTP response headers

  * `{:data, data}` - the HTTP response body chunk

  * `{:trailers, trailers}` - the HTTP response trailers

See also `request/3`, `stream/5`.

> ### HTTP2 streaming and back-pressure {: .warning}
>
> At the moment, streaming over HTTP2 connections do not provide
> any back-pressure mechanism: this means the response will be
> sent to the client as quickly as possible. Therefore, you must
> not use streaming over HTTP2 for non-terminating responses or
> when streaming large responses which you do not intend to keep
> in memory.

> ### Connection draining {: .info}
>
> If the HTTP/2 pool this request is dispatched to is currently draining (see
> `http2: [max_connection_age: ...]`), the request is automatically retried on a fresh
> pool. The retry is transparent to the caller. See `async_request/3` for the async
> variant, which does not retry automatically.

## Options

Shares options with `request/3`.

## Examples

    path = "/tmp/archive.zip"
    file = File.open!(path, [:write, :exclusive])
    request = Finch.build(:get, "https://example.com/archive.zip")

    Finch.stream_while(request, MyFinch, nil, fn
      {:status, status}, acc ->
        IO.inspect(status)
        {:cont, acc}

      {:headers, headers}, acc ->
        IO.inspect(headers)
        {:cont, acc}

      {:data, data}, acc ->
        IO.binwrite(file, data)
        {:cont, acc}
    end)

    File.close(file)

Uploading a file using `req_body_fun`:

    file = File.open!("/tmp/archive.zip", [:read])

    req_body_fun = fn file ->
      case IO.binread(file, 4096) do
        :eof -> {:done, file}
        data -> {:data, data, file}
      end
    end

    request = Finch.build(:post, "https://example.com/upload", [], {:stream, req_body_fun})

    resp_fun = fn
      {:status, status}, acc ->
        IO.inspect(status)
        {:cont, acc}

      {:headers, headers}, acc ->
        IO.inspect(headers)
        {:cont, acc}

      {:data, data}, acc ->
        IO.inspect(data)
        {:cont, acc}
    end

    {:ok, file} = Finch.stream_while(request, MyFinch, file, resp_fun)
    File.close(file)

## request/3

Sends an HTTP request and returns a `Finch.Response` struct.

It can still raise exceptions if it was not possible to check out a connection in the given `:pool_timeout`.

See also `stream/5`.

> ### Connection draining {: .info}
>
> If the HTTP/2 pool this request is dispatched to is currently draining (see
> `http2: [max_connection_age: ...]`), the request is automatically retried on a fresh
> pool. The retry is transparent to the caller. See `async_request/3` for the async
> variant, which does not retry automatically.

## Options

  * `:pool_timeout` - This timeout is applied when we check out a connection from the pool.
    Default value is `5_000`.

  * `:receive_timeout` - The maximum time to wait for each chunk to be received before returning an error.
    Default value is `15_000`.

  * `:request_timeout` - The amount of time to wait for a complete response before returning an error.
    This timeout only applies to HTTP/1, and its current implementation is a best effort timeout,
    it does not guarantee the call will return precisely when the time has elapsed.
    Default value is `:infinity`.

  * `:pool_strategy` - When the pool has multiple shards (`count: N`), selects which shards handles
    the request. Default is random selection. See `t:pool_strategy/0` for details.

## request!/3

Sends an HTTP request and returns a `Finch.Response` struct
or raises an exception in case of failure.

See `request/3` for more detailed information.

## async_request/3

Sends an HTTP request asynchronously, returning a request reference.

If the request is sent using HTTP1, an extra process is spawned to
consume messages from the underlying socket. The messages are sent
to the current process as soon as they arrive, as a firehose.  If
you wish to maximize request rate or have more control over how
messages are streamed, a strategy using `request/3` or `stream/5`
should be used instead.

## Receiving the response

Response information is sent to the calling process as it is received
in `{ref, response}` tuples.

If the calling process exits before the request has completed, the
request will be canceled.

Responses include:

  * `{:status, status}` - HTTP response status
  * `{:headers, headers}` - HTTP response headers
  * `{:data, data}` - section of the HTTP response body
  * `{:error, exception}` - an error occurred during the request
  * `:done` - request has completed successfully

On a successful request, a single `:status` message will be followed
by a single `:headers` message, after which more than one `:data`
messages may be sent. If trailing headers are present, a final
`:headers` message may be sent. Any `:done` or `:error` message
indicates that the request has succeeded or failed and no further
messages are expected.

## Example

    iex> req = Finch.build(:get, "https://httpbin.org/stream/5")
    iex> ref = Finch.async_request(req, MyFinch)
    iex> flush()
    {ref, {:status, 200}}
    {ref, {:headers, [...]}}
    {ref, {:data, "..."}}
    {ref, :done}

> ### Connection draining {: .info}
>
> Unlike `request/3` and `stream/5`, async requests are not automatically retried when a
> pool is draining (see `http2: [max_connection_age: ...]`). If the caller receives
> `{ref, {:error, %Finch.Error{reason: :read_only}}}`, it should retry by calling
> `async_request/3` again.

## Options

Shares options with `request/3`.

## cancel_async_request/1

Cancels a request sent with `async_request/3`.

## get_pool_status/2

Get pool metrics.

When given a URL or pool identifier tuple, this returns the metrics list for that specific
pool. The number of items in the metrics list depends on the configured
`:count` option and each entry will have a `pool_index` going from 1 to
`:count`.

When `:default` is provided, Finch returns the metrics for all pools started
from the `:default` configuration. In this case the return value is a map
keyed by each pool's `{scheme, host, port}` tuple with the corresponding
metrics list as the value.

The metrics struct depends on the pool scheme defined in the `:protocols`
option: `Finch.HTTP1.PoolMetrics` for `:http1` and `Finch.HTTP2.PoolMetrics`
for `:http2`. See the documentation for those modules for more details.

`{:error, :not_found}` is returned in the following scenarios:

  * There is no pool registered for the given Finch instance and pool identifier.
  * The pool has `start_pool_metrics?: false` (the default).
  * `:default` is provided but no pools have been started from the
    `:default` configuration (or none have metrics enabled).

## Examples

    iex> Finch.get_pool_status(MyFinch, "https://httpbin.org")
    {:ok, [
      %Finch.HTTP1.PoolMetrics{
        pool_index: 1,
        pool_size: 50,
        available_connections: 43,
        in_use_connections: 7
      },
      %Finch.HTTP1.PoolMetrics{
        pool_index: 2,
        pool_size: 50,
        available_connections: 37,
        in_use_connections: 13
      }]
    }

    iex> Finch.get_pool_status(MyFinch, :default)
    {:ok,
     %{
       %Finch.Pool{host: "httpbin.com", port: 443, scheme: :https, tag: :default} => [
         %Finch.HTTP1.PoolMetrics{
           pool_index: 1,
           pool_size: 50,
           available_connections: 43,
           in_use_connections: 7
         }
       ]
     }}

## ping/2

Sends an HTTP/2 PING frame and waits for PONG.

Returns `{:ok, rtt_ms}` where `rtt_ms` is the round-trip time in native time units,
or `{:error, reason}` if the ping fails.

This is only supported for HTTP/2 pools. Returns `{:error, :not_http2}` for
HTTP/1 pools.

## Examples

    {:ok, rtt} = Finch.ping(MyFinch, "https://example.com")
    IO.puts("RTT: #{rtt}ms")

## stop_pool/2

Stops the pool of processes associated with the given pool identifier.

This function can be invoked to manually stop the pool for the given identifier
when you know it's not going to be used anymore.

Note that this function is not safe with respect to concurrent requests. Invoking it while
another request to the same pool is taking place might result in the failure of that request.
It is the responsibility of the client to ensure that no request to the same pool is taking
place while this function is being invoked.

## get_pool_count/2

Returns the current worker count for the given pool.

Returns `{:ok, count}` if the pool exists, `{:error, :not_found}` otherwise.

## Examples

    {:ok, count} = Finch.get_pool_count(MyFinch, "https://example.com")

## set_pool_count/3

Dynamically changes the number of pool workers for the given pool.

Returns `:ok` on success, `{:error, :not_found}` if the pool doesn't exist.

Works with all kinds of pools, but note that `:default` pools must have
been materialized by at least one request before they can be resized.

## Examples

    :ok = Finch.set_pool_count(MyFinch, "https://example.com", 4)