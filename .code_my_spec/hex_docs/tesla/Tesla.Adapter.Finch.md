# Tesla.Adapter.Finch

Adapter for [finch](https://github.com/sneako/finch).

Remember to add `{:finch, "~> 0.14.0"}` to dependencies. Also, you need to
recompile tesla after adding the `:finch` dependency:

```shell
mix deps.clean tesla
mix compile
```

## Examples

In order to use Finch, you must start it and provide a `:name`. For example,
in your supervision tree:

```elixir
children = [
  {Finch, name: MyFinch}
]
```

You must provide the same name to this adapter:

```elixir
# set globally in config/config.exs
config :tesla, :adapter, {Tesla.Adapter.Finch, name: MyFinch}

# set per module
defmodule MyClient do
  def client do
    Tesla.client([], {Tesla.Adapter.Finch, name: MyFinch})
  end
end
```

## Adapter specific options

  * `:name` - The `:name` provided to Finch (**required**).
  * `:response` - Expected response type. Defines the Finch request type
    to use. Supported values:
    + `:stream` - Streams the response using `Finch.stream/5` for the
      request.
    + `nil` or not specified - Responds without streaming using
      `Finch.request/3`.

## [Finch build options](https://hexdocs.pm/finch/Finch.html#build/5)

  * `:unix_socket` - Path to a Unix domain socket to connect to instead of the
    URL host/port. The URL scheme still determines whether HTTP or HTTPS is used.

  * `:pool_tag` - The tag to use when selecting which pool to use for this request.
    Defaults to `:default`. See [Finch - Pool Tagging](https://hexdocs.pm/finch/Finch.html#module-pool-tagging).

## [Finch request options](https://hexdocs.pm/finch/Finch.html#t:request_opt/0)

  * `:pool_timeout` - This timeout is applied when a connection is checked
    out from the pool. Default value is `5_000`.

  * `:receive_timeout` - The maximum time to wait for each chunk to arrive
    before returning an error. Default value is `15_000`.

  * `:request_timeout` - The maximum time to wait for a complete response
    before returning an error. Only applies to HTTP/1. Default value is `:infinity`.

  * `:pool_strategy` - Determines which shard handles the request when the pool
    has multiple shards (`count > 1`). Default selection is random.