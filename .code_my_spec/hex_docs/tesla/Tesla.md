# Tesla

A HTTP toolkit for building API clients using middlewares.

## Building API client

Use `Tesla.client/2` to build a client with the given middleware and adapter.

### Examples

```elixir
defmodule ExampleApi do
  def client do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, "http://api.example.com"},
      Tesla.Middleware.JSON
    ])
  end

  def fetch_data(client) do
    Tesla.get(client, "/data")
  end
end
```

Now you can use `ExampleApi.client/0` to make requests to the API.

```elixir
client = ExampleApi.client()
ExampleApi.fetch_data(client)
```

## Direct usage

It is also possible to do request directly with `Tesla` module.

```elixir
Tesla.get("https://example.com")
```

## Default adapter

By default `Tesla` is using `Tesla.Adapter.Httpc`, because `:httpc` is
included in Erlang/OTP and does not require installation of any additional
dependency. It can be changed globally with config:

```elixir
config :tesla, :adapter, Tesla.Adapter.Mint
```

## Assigns and Private

`Tesla.Env` has two map fields for storing additional data: `:assigns` and `:private`.

`:assigns` is a place for user data. It can be used to carry application-specific metadata
through the middleware pipeline.

`:private` is a map reserved for libraries and middleware to use. The keys must be atoms.
Prefix the keys with the name of your project to avoid any future conflicts. The `tesla_`
prefix is reserved for Tesla.

## put_opt/3

Adds given key/value pair to `:opts` field in `Tesla.Env`.

Useful when there's a need to store additional middleware data in `Tesla.Env`

## Examples

    iex> %Tesla.Env{opts: []} |> Tesla.put_opt(:option, "value")
    %Tesla.Env{opts: [option: "value"]}

## put_assigns/2

Merges the given assigns into `Tesla.Env`.

## Examples

    iex> env = %Tesla.Env{}
    iex> env = Tesla.put_assigns(env, %{user_id: 123, role: :admin})
    iex> env.assigns
    %{user_id: 123, role: :admin}

    iex> env = %Tesla.Env{assigns: %{user_id: 123}}
    iex> env = Tesla.put_assigns(env, %{role: :admin})
    iex> env.assigns
    %{user_id: 123, role: :admin}

## put_assign/3

Assigns key/value to `Tesla.Env`.

## Examples

    iex> env = %Tesla.Env{}
    iex> env = Tesla.put_assign(env, :user_id, 123)
    iex> env.assigns
    %{user_id: 123}

## put_assign_new/3

Assigns key/value to `Tesla.Env` unless the key is already set.

## Examples

    iex> env = %Tesla.Env{}
    iex> env = Tesla.put_assign_new(env, :user_id, 123)
    iex> env = Tesla.put_assign_new(env, :user_id, 456)
    iex> env.assigns
    %{user_id: 123}

## update_assign!/3

Updates assign `key` in `Tesla.Env` with the given function.

Raises if the `key` is not set.

See also `update_assign/4`.

## Examples

    iex> env = %Tesla.Env{assigns: %{counter: 1}}
    iex> env = Tesla.update_assign!(env, :counter, &(&1 + 1))
    iex> env.assigns
    %{counter: 2}

## update_assign/4

Updates assign `key` in `Tesla.Env` with the given function or `default`.

If `key` is present in assigns then the existing value is passed to `fun` and its
result is used as the updated value of `key`. If `key` is not present in assigns,
`default` is inserted as the value of `key`. The `default` value will not be passed
through the update function.

See also `update_assign!/3`.

## Examples

    iex> env = %Tesla.Env{assigns: %{counter: 10}}
    iex> env = Tesla.update_assign(env, :counter, 1, &(&1 + 1))
    iex> env = Tesla.update_assign(env, :other, 1, &(&1 + 1))
    iex> env.assigns
    %{counter: 11, other: 1}

## get_header/2

Returns value of header specified by `key` from `:headers` field in `Tesla.Env`.

## Examples

    # non existing header
    iex> env = %Tesla.Env{headers: [{"server", "Cowboy"}]}
    iex> Tesla.get_header(env, "some-key")
    nil

    # existing header
    iex> env = %Tesla.Env{headers: [{"server", "Cowboy"}]}
    iex> Tesla.get_header(env, "server")
    "Cowboy"

    # first of multiple headers with the same name
    iex> env = %Tesla.Env{headers: [{"cookie", "chocolate"}, {"cookie", "biscuits"}]}
    iex> Tesla.get_header(env, "cookie")
    "chocolate"

## client/2

Dynamically build client from list of middlewares and/or adapter.

```
# add dynamic middleware
client = Tesla.client([{Tesla.Middleware.Headers, [{"authorization", token}]}])
Tesla.get(client, "/path")

# configure adapter in runtime
client = Tesla.client([], Tesla.Adapter.Hackney)
client = Tesla.client([], {Tesla.Adapter.Hackney, pool: :my_pool})
Tesla.get(client, "/path")

# complete module example
defmodule MyApi do
  @middleware [
    {Tesla.Middleware.BaseUrl, "https://example.com"},
    Tesla.Middleware.JSON,
    Tesla.Middleware.Logger
  ]

  @adapter Tesla.Adapter.Hackney

  def new(opts) do
    # do any middleware manipulation you need
    middleware = [
      {Tesla.Middleware.BasicAuth, username: opts[:username], password: opts[:password]}
    ] ++ @middleware

    # allow configuring adapter in runtime
    adapter = opts[:adapter] || @adapter

    # use Tesla.client/2 to put it all together
    Tesla.client(middleware, adapter)
  end

  def get_something(client, id) do
    # pass client directly to Tesla.get/2
    Tesla.get(client, "/something/#{id}")
    # ...
  end
end

client = MyApi.new(username: "admin", password: "secret")
MyApi.get_something(client, 42)
```

## build_url/3

Builds URL with the given URL and query params.

Useful when you need to create a URL with dynamic query params from a Keyword
list

Allows to specify the `encoding` strategy as either `:www_form`,
`:rfc3986`, or a custom function that receives the query params and returns
the encoded query string.

- `url` - the base URL to which the query params will be appended.
- `query` - a list of key-value pairs to be encoded as query params.
- `encoding` - the encoding strategy to use. Defaults to `:www_form`

## Examples

    iex> Tesla.build_url("https://api.example.com", [user: 3, page: 2])
    "https://api.example.com?user=3&page=2"

URL that already contains query params:

    iex> url = "https://api.example.com?user=3"
    iex> Tesla.build_url(url, [page: 2, status: true])
    "https://api.example.com?user=3&page=2&status=true"

Default encoding `:www_form`:

    iex> Tesla.build_url("https://api.example.com", [user_name: "John Smith"])
    "https://api.example.com?user_name=John+Smith"

Specified encoding strategy `:rfc3986`:

    iex> Tesla.build_url("https://api.example.com", [user_name: "John Smith"], :rfc3986)
    "https://api.example.com?user_name=John%20Smith"

Custom encoding function:

    Tesla.get(
      "http://example.com",
      query: [username: "John Smith"],
      opts: [query_encoding: &Plug.Conn.Query.encode/1]
    )

    Tesla.build_url(
      "https://api.example.com",
      [filters: [pagination: [page: 2]]],
      &Plug.Conn.Query.encode/1
    )
    #=> "https://api.example.com?filters[pagination][page]=2"

This keeps query params structured inside Tesla while letting applications
delegate serialization to encoders such as `Plug.Conn.Query.encode/1`.

When query params are passed as maps, the encoded parameter order is
unspecified. Pass an ordered list of pairs if the exact query string order
matters.

Pass `t:Tesla.OpenAPI.QueryString.t/0` as the query when the entire query string is
already serialized as one value:

    iex> query = Tesla.OpenAPI.QueryString.raw!("foo=a+%2B+b&bar=true")
    iex> Tesla.build_url("https://api.example.com", query)
    "https://api.example.com?foo=a+%2B+b&bar=true"

## build_url/1

Builds a URL from the given `t:Tesla.Env.t/0` struct.

Combines the `url` and `query` fields, and allows specifying the `encoding`
strategy before calling `build_url/3`.