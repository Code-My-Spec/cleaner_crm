# Req.Request



## new/1

Returns a new request struct.

## Options

  * `:method` - the request method, defaults to `:get`.

  * `:url` - the request URL.

  * `:headers` - the request headers, defaults to `[]`.

  * `:body` - the request body, defaults to `nil`.

  * `:adapter` - the request adapter, defaults to calling [`run_finch`](`Req.Steps.run_finch/1`).

## Examples

    iex> req = Req.Request.new(url: "https://api.github.com/repos/wojtekmach/req")
    iex> {req, resp} = Req.Request.run_request(req)
    iex> req.url.host
    "api.github.com"
    iex> resp.status
    200

## put_option/3

Sets the value `value` for the option `name`.

See also `put_new_option/3`, `merge_options/2`, and `merge_new_options/2`.

## Examples

    iex> req = Req.Request.new() |> Req.Request.register_options([:a])
    iex> req.options
    %{}
    iex> req = Req.Request.put_option(req, :a, 1)
    iex> req.options
    %{a: 1}

    iex> req = Req.Request.new()
    iex> Req.Request.put_option(req, :b, 2)
    ** (ArgumentError) unknown option :b

## put_new_option/3

Sets the value `value` for the option `name` unless option is already set.

See also `put_option/3`, `merge_options/2`, and `merge_new_options/2`.

## Examples

    iex> req = Req.Request.new() |> Req.Request.register_options([:a])
    iex> req.options
    %{}
    iex> req = Req.Request.put_new_option(req, :a, 1)
    iex> req.options
    %{a: 1}
    iex> req = Req.Request.put_new_option(req, :a, 2)
    iex> req.options
    %{a: 1}

    iex> req = Req.Request.new()
    iex> Req.Request.put_new_option(req, :b, 2)
    ** (ArgumentError) unknown option :b

## get_option/3

Gets the value for the option `key`.

See also `fetch_option!/2`.

## Examples

    iex> req = Req.Request.new(options: [a: 1])
    iex> Req.Request.get_option(req, :a)
    1
    iex> Req.Request.get_option(req, :b)
    nil
    iex> Req.Request.get_option(req, :b, 0)
    0

## get_option_lazy/3

Gets the value for the option `key`.

This is useful if the default value is very expensive to calculate or generally
difficult to setup and teardown again.

See also `get_option/3`.

## Examples

    iex> req = Req.Request.new(options: [a: 1])
    iex> fun = fn ->
    ...>   # some expensive operation here
    ...>   42
    ...> end
    iex> Req.Request.get_option_lazy(req, :a, fun)
    1
    iex> Req.Request.get_option_lazy(req, :b, fun)
    42

## fetch_option/2

Fetches the value for the option `key`.

See also `get_option/3`.

## Examples

    iex> req = Req.Request.new(options: [a: 1])
    iex> Req.Request.fetch_option(req, :a)
    {:ok, 1}
    iex> Req.Request.fetch_option(req, :b)
    :error

## fetch_option!/2

Fetches the value for the option `key` or raises if it's not set.

See also `get_option/3`.

## Examples

    iex> req = Req.Request.new(options: [a: 1])
    iex> Req.Request.fetch_option!(req, :a)
    1
    iex> Req.Request.fetch_option!(req, :b)
    ** (KeyError) option :b is not set

## delete_option/2

Deletes the given option `key`.

## Examples

    iex> req = Req.Request.new(options: [a: 1])
    iex> Req.Request.get_option(req, :a)
    1
    iex> req = Req.Request.delete_option(req, :a)
    iex> Req.Request.get_option(req, :a)
    nil

## drop_options/2

Drops the given `keys` from options.

## Examples

    iex> req = Req.Request.new(options: [a: 1, b: 2, c: 3])
    iex> req = Req.Request.drop_options(req, [:a, :b])
    iex> Req.Request.get_option(req, :a)
    nil
    iex> Req.Request.get_option(req, :c)
    3

## get_private/3

Gets the value for a specific private `key`.

## update_private/4

Updates private `key` with the given function.

If `key` is present in request private map then the existing value is passed to `fun` and its
result is used as the updated value of `key`. If `key` is not present, `default` is inserted
as the value of `key`. The default value will not be passed through the update function.

## Examples

    iex> req = %Req.Request{private: %{a: 1}}
    iex> Req.Request.update_private(req, :a, 11, & &1 + 1).private
    %{a: 2}
    iex> Req.Request.update_private(req, :b, 11, & &1 + 1).private
    %{a: 1, b: 11}

## put_private/3

Assigns a private `key` to `value`.

## halt/2

Halts the request pipeline preventing any further steps from executing.

This function returns an updated request and the response or exception that caused the halt.
It's perfect when used in a request step to stop the pipeline.

See the ["Halting"](#module-halting) section in the module documentation for more information.

## Examples

    Req.Request.prepend_request_steps(request, circuit_breaker: fn request ->
      if CircuitBreaker.open?() do
        Req.Request.halt(request, RuntimeError.exception("circuit breaker is open"))
      else
        request
      end
    end)

## append_request_steps/2

Appends **request steps** to the existing request steps.

See the ["Request Steps"](#module-request-steps) section in the module documentation
for more information.

## Examples

    Req.Request.append_request_steps(request,
      noop: fn request -> request end,
      inspect: &IO.inspect/1
    )

## prepend_request_steps/2

Prepends **request steps** to the existing request steps.

See the ["Request Steps"](#module-request-steps) section in the module documentation
for more information.

## Examples

    Req.Request.prepend_request_steps(request,
      noop: fn request -> request end,
      inspect: &IO.inspect/1
    )

## append_response_steps/2

Appends **response steps** to the existing response steps.

See the ["Response and Error Steps"](#module-response-and-error-steps) section in the
module documentation for more information.

## Examples

    Req.Request.append_response_steps(request,
      noop: fn {request, response} -> {request, response} end,
      inspect: &IO.inspect/1
    )

## prepend_response_steps/2

Prepends **response steps** to the existing response steps.

See the ["Response and Error Steps"](#module-response-and-error-steps) section in the
module documentation for more information.

## Examples

    Req.Request.prepend_response_steps(request,
      noop: fn {request, response} -> {request, response} end,
      inspect: &IO.inspect/1
    )

## append_error_steps/2

Appends **error steps** to the existing error steps.

See the ["Response and Error Steps"](#module-response-and-error-steps) section in the
module documentation for more information.

## Examples

    Req.Request.append_error_steps(request,
      noop: fn {request, exception} -> {request, exception} end,
      inspect: &IO.inspect/1
    )

## prepend_error_steps/2

Prepends **error steps** to the existing error steps.

See the ["Response and Error Steps"](#module-response-and-error-steps) section in the
module documentation for more information.

## Examples

    Req.Request.prepend_error_steps(request,
      noop: fn {request, exception} -> {request, exception} end,
      inspect: &IO.inspect/1
    )

## merge_options/2

Merges given options into the request.

## Examples

    iex> req = Req.new(auth: {:basic, "alice:secret"}, http_errors: :raise)
    iex> req = Req.Request.merge_options(req, auth: {:bearer, "abcd"}, base_url: "https://example.com")
    iex> req.options[:auth]
    {:bearer, "abcd"}
    iex> req.options[:http_errors]
    :raise
    iex> req.options[:base_url]
    "https://example.com"

## merge_new_options/2

Merges given options into the request unless they are already set.

## Examples

    iex> req = Req.new(auth: {:basic, "alice:secret"})
    iex> req.options
    %{auth: {:basic, "alice:secret"}}
    iex> req = Req.Request.merge_new_options(req, auth: {:bearer, "abcd"}, base_url: "https://example.com")
    iex> req.options
    %{auth: {:basic, "alice:secret"}, base_url: "https://example.com"}

    iex> req = Req.new()
    iex> Req.Request.merge_new_options(req, foo: :bar)
    ** (ArgumentError) unknown option :foo

## get_header/2

Returns the values of the header specified by `name`.

See also "Headers" section in `Req` module documentation.

## Examples

    iex> req = Req.new(headers: [{"accept", "application/json"}])
    iex> Req.Request.get_header(req, "accept")
    ["application/json"]
    iex> Req.Request.get_header(req, "x-unknown")
    []

## put_header/3

Sets the header `name` to `value`.

The value can be a binary or a list of binaries,

If the header was previously set, its value is overwritten.

See also "Headers" section in `Req` module documentation.

## Examples

    iex> req = Req.new()
    iex> Req.Request.get_header(req, "accept")
    []
    iex> req = Req.Request.put_header(req, "accept", "application/json")
    iex> Req.Request.get_header(req, "accept")
    ["application/json"]

## put_headers/2

Adds (or replaces) multiple request headers.

See `put_header/3` for more information.

## Examples

    iex> req = Req.new()
    iex> req = Req.Request.put_headers(req, [{"accept", "text/html"}, {"accept-encoding", "gzip"}])
    iex> Req.Request.get_header(req, "accept")
    ["text/html"]
    iex> Req.Request.get_header(req, "accept-encoding")
    ["gzip"]

## put_new_header/3

Adds a request header `name` unless already present.

See `put_header/3` for more information.

## Examples

    iex> req =
    ...>   Req.new()
    ...>   |> Req.Request.put_new_header("accept", "application/json")
    ...>   |> Req.Request.put_new_header("accept", "application/html")
    iex> Req.Request.get_header(req, "accept")
    ["application/json"]

## delete_header/2

Deletes the header given by `name`.

All occurrences of the header are deleted, in case the header is repeated multiple times.

See also "Headers" section in `Req` module documentation.

## Examples

    iex> Req.Request.get_header(req, "cache-control")
    ["max-age=600", "no-transform"]
    iex> req = Req.Request.delete_header(req, "cache-control")
    iex> Req.Request.get_header(req, "cache-control")
    []

## register_options/2

Registers options to be used by a custom steps.

Req ensures that all used options were previously registered which helps
finding accidentally mistyped option names. If you're adding custom steps
that are accepting options, call this function to register them.

## Examples

    iex> Req.request!(urll: "https://httpbin.org")
    ** (ArgumentError) unknown option :urll. Did you mean :url?

    iex> Req.new(bas_url: "https://httpbin.org")
    ** (ArgumentError) unknown option :bas_url. Did you mean :base_url?

    req =
      Req.new(base_url: "https://httpbin.org")
      |> Req.Request.register_options([:foo])

    Req.get!(req, url: "/status/201", foo: :bar).status
    #=> 201

## run_request/1

Runs the request pipeline.

Returns `{request, response}` or `{request, exception}`.

## Examples

    iex> req = Req.Request.new(url: "https://api.github.com/repos/wojtekmach/req")
    iex> {request, response} = Req.Request.run_request(req)
    iex> request.url.host
    "api.github.com"
    iex> response.status
    200