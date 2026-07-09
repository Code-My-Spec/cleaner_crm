# Req



## merge/2

Updates a request struct.

See `new/1` for a list of available options. Also see `Req.Request` module documentation
for more information on the underlying request struct.

## Examples

    iex> req = Req.new(base_url: "https://httpbin.org")
    iex> req = Req.merge(req, auth: {:basic, "alice:secret"})
    iex> req.options[:base_url]
    "https://httpbin.org"
    iex> req.options[:auth]
    {:basic, "alice:secret"}

Passing `:headers` will automatically encode and merge them:

    iex> req = Req.new(headers: %{point_x: 1})
    iex> req = Req.merge(req, headers: %{point_y: 2})
    iex> req.headers
    %{"point-x" => ["1"], "point-y" => ["2"]}

The same header names are overwritten however:

    iex> req = Req.new(headers: %{authorization: "bearer foo"})
    iex> req = Req.merge(req, headers: %{authorization: "bearer bar"})
    iex> req.headers
    %{"authorization" => ["bearer bar"]}

Similarly to headers, `:params` are merged too:

    req = Req.new(url: "https://httpbin.org/anything", params: [a: 1, b: 1])
    req = Req.merge(req, params: [a: 2])
    Req.get!(req).body["args"]
    #=> %{"a" => "2", "b" => "1"}

## get/2

Makes a GET request and returns a response or an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> {:ok, resp} = Req.get("https://api.github.com/repos/wojtekmach/req")
    iex> resp.body["description"]
    "Req is a batteries-included HTTP client for Elixir."

With options:

    iex> {:ok, resp} = Req.get(url: "https://api.github.com/repos/wojtekmach/req")
    iex> resp.status
    200

With request struct:

    iex> req = Req.new(base_url: "https://api.github.com")
    iex> {:ok, resp} = Req.get(req, url: "/repos/elixir-lang/elixir")
    iex> resp.status
    200

## get!/2

Makes a GET request and returns a response or raises an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> Req.get!("https://api.github.com/repos/wojtekmach/req").body["description"]
    "Req is a batteries-included HTTP client for Elixir."

With options:

    iex> Req.get!(url: "https://api.github.com/repos/wojtekmach/req").status
    200

With request struct:

    iex> req = Req.new(base_url: "https://api.github.com")
    iex> Req.get!(req, url: "/repos/elixir-lang/elixir").status
    200

## head/2

Makes a HEAD request and returns a response or an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> {:ok, resp} = Req.head("https://httpbin.org/status/201")
    iex> resp.status
    201

With options:

    iex> {:ok, resp} = Req.head(url: "https://httpbin.org/status/201")
    iex> resp.status
    201

With request struct:

    iex> req = Req.new(base_url: "https://httpbin.org")
    iex> {:ok, resp} = Req.head(req, url: "/status/201")
    iex> resp.status
    201

## head!/2

Makes a HEAD request and returns a response or raises an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> Req.head!("https://httpbin.org/status/201").status
    201

With options:

    iex> Req.head!(url: "https://httpbin.org/status/201").status
    201

With request struct:

    iex> req = Req.new(base_url: "https://httpbin.org")
    iex> Req.head!(req, url: "/status/201").status
    201

## post/2

Makes a POST request and returns a response or an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> {:ok, resp} = Req.post("https://httpbin.org/anything", body: "hello!")
    iex> resp.body["data"]
    "hello!"

    iex> {:ok, resp} = Req.post("https://httpbin.org/anything", form: [x: 1])
    iex> resp.body["form"]
    %{"x" => "1"}

    iex> {:ok, resp} = Req.post("https://httpbin.org/anything", json: %{x: 2})
    iex> resp.body["json"]
    %{"x" => 2}

With options:

    iex> {:ok, resp} = Req.post(url: "https://httpbin.org/anything", body: "hello!")
    iex> resp.body["data"]
    "hello!"

With request struct:

    iex> req = Req.new(url: "https://httpbin.org/anything")
    iex> {:ok, resp} = Req.post(req, body: "hello!")
    iex> resp.body["data"]
    "hello!"

## post!/2

Makes a POST request and returns a response or raises an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> Req.post!("https://httpbin.org/anything", body: "hello!").body["data"]
    "hello!"

    iex> Req.post!("https://httpbin.org/anything", form: [x: 1]).body["form"]
    %{"x" => "1"}

    iex> Req.post!("https://httpbin.org/anything", json: %{x: 2}).body["json"]
    %{"x" => 2}

With options:

    iex> Req.post!(url: "https://httpbin.org/anything", body: "hello!").body["data"]
    "hello!"

With request struct:

    iex> req = Req.new(url: "https://httpbin.org/anything")
    iex> Req.post!(req, body: "hello!").body["data"]
    "hello!"

## put/2

Makes a PUT request and returns a response or an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> {:ok, resp} = Req.put("https://httpbin.org/anything", body: "hello!")
    iex> resp.body["data"]
    "hello!"

With options:

    iex> {:ok, resp} = Req.put(url: "https://httpbin.org/anything", body: "hello!")
    iex> resp.body["data"]
    "hello!"

With request struct:

    iex> req = Req.new(url: "https://httpbin.org/anything")
    iex> {:ok, resp} = Req.put(req, body: "hello!")
    iex> resp.body["data"]
    "hello!"

## put!/2

Makes a PUT request and returns a response or raises an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> Req.put!("https://httpbin.org/anything", body: "hello!").body["data"]
    "hello!"

With options:

    iex> Req.put!(url: "https://httpbin.org/anything", body: "hello!").body["data"]
    "hello!"

With request struct:

    iex> req = Req.new(url: "https://httpbin.org/anything")
    iex> Req.put!(req, body: "hello!").body["data"]
    "hello!"

## patch/2

Makes a PATCH request and returns a response or an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> {:ok, resp} = Req.patch("https://httpbin.org/anything", body: "hello!")
    iex> resp.body["data"]
    "hello!"

With options:

    iex> {:ok, resp} = Req.patch(url: "https://httpbin.org/anything", body: "hello!")
    iex> resp.body["data"]
    "hello!"

With request struct:

    iex> req = Req.new(url: "https://httpbin.org/anything")
    iex> {:ok, resp} = Req.patch(req, body: "hello!")
    iex> resp.body["data"]
    "hello!"

## patch!/2

Makes a PATCH request and returns a response or raises an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> Req.patch!("https://httpbin.org/anything", body: "hello!").body["data"]
    "hello!"

With options:

    iex> Req.patch!(url: "https://httpbin.org/anything", body: "hello!").body["data"]
    "hello!"

With request struct:

    iex> req = Req.new(url: "https://httpbin.org/anything")
    iex> Req.patch!(req, body: "hello!").body["data"]
    "hello!"

## delete/2

Makes a DELETE request and returns a response or an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> {:ok, resp} = Req.delete("https://httpbin.org/anything")
    iex> resp.body["method"]
    "DELETE"

With options:

    iex> {:ok, resp} = Req.delete(url: "https://httpbin.org/anything")
    iex> resp.body["method"]
    "DELETE"

With request struct:

    iex> req = Req.new(url: "https://httpbin.org/anything")
    iex> {:ok, resp} = Req.delete(req)
    iex> resp.body["method"]
    "DELETE"

## delete!/2

Makes a DELETE request and returns a response or raises an error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

## Examples

With URL:

    iex> Req.delete!("https://httpbin.org/anything").body["method"]
    "DELETE"

With options:

    iex> Req.delete!(url: "https://httpbin.org/anything").body["method"]
    "DELETE"

With request struct:

    iex> req = Req.new(url: "https://httpbin.org/anything")
    iex> Req.delete!(req).body["method"]
    "DELETE"

## request/2

Makes an HTTP request and returns a response or an error.

`request` can be one of:

  * a `Keyword` options;
  * a `Req.Request` struct

See `new/1` for a list of available options.

Also see `run/2` for a similar function that returns the request and the response or error.

## Examples

With options keywords list:

    iex> {:ok, response} = Req.request(url: "https://api.github.com/repos/wojtekmach/req")
    iex> response.status
    200
    iex> response.body["description"]
    "Req is a batteries-included HTTP client for Elixir."

With request struct:

    iex> req = Req.new(url: "https://api.github.com/repos/elixir-lang/elixir")
    iex> {:ok, response} = Req.request(req)
    iex> response.status
    200

## request!/2

Makes an HTTP request and returns a response or raises an error.

See `new/1` for a list of available options.

Also see `run!/2` for a similar function that returns the request and the response or error.

## Examples

With options keywords list:

    iex> Req.request!(url: "https://api.github.com/repos/elixir-lang/elixir").status
    200

With request struct:

    iex> req = Req.new(url: "https://api.github.com/repos/elixir-lang/elixir")
    iex> Req.request!(req).status
    200

## run/2

Makes an HTTP request and returns the request and response or error.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

Also see `request/2` for a similar function that returns the response or error
(without the request).

## Examples

With options keywords list:

    iex> {req, resp} = Req.run(url: "https://api.github.com/repos/elixir-lang/elixir")
    iex> req.url.host
    "api.github.com"
    iex> resp.status
    200

With request struct and options:

    iex> req = Req.new(base_url: "https://api.github.com")
    iex> {req, resp} = Req.run(req, url: "/repos/elixir-lang/elixir")
    iex> req.url.host
    "api.github.com"
    iex> resp.status
    200

Returns an error:

    iex> {_req, exception} = Req.run("http://localhost:9999", retry: false)
    iex> exception
    %Req.TransportError{reason: :econnrefused}

## run!/2

Makes an HTTP request and returns the request and response or raises on errors.

`request` can be one of:

  * an url (`String` or `URI`);

  * a `Keyword` options;

  * a `Req.Request` struct

See `new/1` for a list of available options.

Also see `request!/2` for a similar function that returns the response (without the request).

## Examples

With options keywords list:

    iex> {req, resp} = Req.run!(url: "https://api.github.com/repos/elixir-lang/elixir")
    iex> req.url.host
    "api.github.com"
    iex> resp.status
    200

With request struct and options:

    iex> req = Req.new(base_url: "https://api.github.com")
    iex> {req, resp} = Req.run!(req, url: "/repos/elixir-lang/elixir")
    iex> req.url.host
    "api.github.com"
    iex> resp.status
    200

Raises an error:

    iex> Req.run!("http://localhost:9999", retry: false)
    ** (Req.TransportError) connection refused

## parse_message/2

Parses asynchronous response body message.

A request with option `:into` set to `:self` returns response with asynchronous body.
In that case, Req sends chunks to the calling process as messages. You'd typically
get them using `receive/1` or [`handle_info/2`](`c:GenServer.handle_info/2`) in a GenServer.
These messages should be parsed using this function. The possible return values are:

  * `{:ok, chunks}` - where a chunk can be `{:data, binary}`, `{:trailers, trailers}`, or
    `:done`.

  * `{:error, reason}` - an error occured

  * `:unknown` - the message was not meant for this response.

See also `Req.Response.Async`.

## Examples

    iex> resp = Req.get!("http://httpbin.org/stream/2", into: :self)
    iex> Req.parse_message(resp, receive do message -> message end)
    {:ok, [data: "{"url": "http://httpbin.org/stream/2", ..., "id": 0}\n"]}
    iex> Req.parse_message(resp, receive do message -> message end)
    {:ok, [data: "{"url": "http://httpbin.org/stream/2", ..., "id": 1}\n"]}
    iex> Req.parse_message(resp, receive do message -> message end)
    {:ok, [:done]}
    iex> Req.parse_message(resp, :other)
    :unknown

## cancel_async_response/1

Cancels an asynchronous response.

An asynchronous response is a result of request with `into: :self`.
See also `Req.Response.Async`.

## Examples

    iex> resp = Req.get!("http://httpbin.org/stream/2", into: :self)
    iex> Req.cancel_async_response(resp)
    :ok

## default_options/0

Returns default options.

See `default_options/1` for more information.

## default_options/1

Sets default options for `Req.new/1`.

Avoid setting default options in libraries as they are global.

## Examples

    iex> Req.default_options(base_url: "https://httpbin.org")
    iex> Req.get!("/statuses/201").status
    201
    iex> Req.new() |> Req.get!(url: "/statuses/201").status
    201

## get_headers_list/1

Returns request/response headers as list.

## Examples

    iex> req = Req.Request.new(headers: %{"accept" => ["application/json"]})
    iex> Req.get_headers_list(req)
    [{"accept", "application/json"}]

    iex> resp = Req.Response.new(headers: %{"content-type" => ["application/json"]})
    iex> Req.get_headers_list(resp)
    [{"content-type", "application/json"}]