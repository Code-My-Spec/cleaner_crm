# Req.Response

The response struct.

Fields:

  * `:status` - the HTTP status code.

  * `:headers` - the HTTP response headers. The header names should be downcased.
    See also "Headers" section in `Req` module documentation.

  * `:body` - the HTTP response body.

  * `:trailers` - the HTTP response trailers. The trailer names must be downcased.

  * `:private` - a map reserved for libraries and frameworks to use.
    Prefix the keys with the name of your project to avoid any future
    conflicts. Only accepts `t:atom/0` keys.

## new/1

Returns a new response.

Expects a keyword list, map, or struct containing the response keys.

## Example

    iex> Req.Response.new(status: 200, body: "body")
    %Req.Response{status: 200, headers: %{}, body: "body"}

    iex> finch_response = %Finch.Response{status: 200, headers: [{"content-type", "text/html"}]}
    iex> Req.Response.new(finch_response)
    %Req.Response{status: 200, headers: %{"content-type" => ["text/html"]}, body: ""}

## to_map/1

Converts response to a map for interoperability with other libraries.

The resulting map has the folowing fields:

  * `:status`
  * `:headers`
  * `:trailers`
  * `:body`

Note, `body` can be any term since Req built-in and custom steps usually transform it.

## Examples

    iex> resp = Req.Response.new(status: 200, headers: %{"server" => ["test"]}, body: "hello")
    iex> Req.Response.to_map(resp)
    %{status: 200, body: "hello", headers: [{"server", "test"}], trailers: []}

## json/2

Builds or updates a response with JSON body.

## Example

    iex> Req.Response.json(%{hello: 42})
    %Req.Response{
      status: 200,
      headers: %{"content-type" => ["application/json"]},
      body: ~s|{"hello":42}|
    }

    iex> resp = Req.Response.new()
    iex> Req.Response.json(resp, %{hello: 42})
    %Req.Response{
      status: 200,
      headers: %{"content-type" => ["application/json"]},
      body: ~s|{"hello":42}|
    }

If the request already contains a 'content-type' header, it is kept as is:

    iex> Req.Response.new()
    iex> |> Req.Response.put_header("content-type", "application/vnd.api+json; charset=utf-8")
    iex> |> Req.Response.json(%{hello: 42})
    %Req.Response{
      status: 200,
      headers: %{"content-type" => ["application/vnd.api+json; charset=utf-8"]},
      body: ~s|{"hello":42}|
    }

## get_private/3

Gets the value for a specific private `key`.

## put_private/3

Assigns a private `key` to `value`.

## update_private/4

Updates private `key` with the given function.

If `key` is present in request private map then the existing value is passed to `fun` and its
result is used as the updated value of `key`. If `key` is not present, `default` is inserted
as the value of `key`. The default value will not be passed through the update function.

## Examples

    iex> resp = %Req.Response{private: %{a: 1}}
    iex> Req.Response.update_private(resp, :a, 11, & &1 + 1).private
    %{a: 2}
    iex> Req.Response.update_private(resp, :b, 11, & &1 + 1).private
    %{a: 1, b: 11}

## get_header/2

Returns the values of the header specified by `name`.

See also "Headers" section in `Req` module documentation.

## Examples

    iex> Req.Response.get_header(response, "content-type")
    ["application/json"]

## put_header/3

Adds a new response header `name` if not present, otherwise replaces the
previous value of that header with `value`.

See also "Headers" section in `Req` module documentation.

## Examples

    iex> resp = Req.Response.put_header(%Req.Response{}, "content-type", "application/json")
    iex> resp.headers
    %{"content-type" => ["application/json"]}

## delete_header/2

Deletes the header given by `name`.

All occurrences of the header are deleted, in case the header is repeated multiple times.

See also "Headers" section in `Req` module documentation.

## Examples

    iex> Req.Response.get_header(resp, "cache-control")
    ["max-age=600", "no-transform"]
    iex> resp = Req.Response.delete_header(resp, "cache-control")
    iex> Req.Response.get_header(resp, "cache-control")
    []

## get_retry_after/1

Returns the `retry-after` header delay value in seconds.

Returns `nil` if the header is not found or the computed number of seconds is negative.