# Tesla.Adapter.Mint

Adapter for [mint](https://github.com/elixir-mint/mint).

**NOTE:** The minimum supported Elixir version for mint is 1.5.0

Remember to add `{:mint, "~> 1.0"}` and `{:castore, "~> 0.1"}` to dependencies.
Also, you need to recompile tesla after adding `:mint` dependency:

```shell
mix deps.clean tesla
mix deps.compile tesla
```

## Examples

```elixir
# set globally in config/config.exs
config :tesla, :adapter, Tesla.Adapter.Mint
# set per module
defmodule MyClient do
  def client do
    Tesla.client([], Tesla.Adapter.Mint)
  end
end

# set global custom cacertfile
config :tesla, adapter: {Tesla.Adapter.Mint, cacert: ["path_to_cacert"]}
```

## Adapter specific options:

- `:timeout` - Time in milliseconds, while process, will wait for mint messages. Defaults to `2_000`.
- `:body_as` - What will be returned in `%Tesla.Env{}` body key. Possible values - `:plain`, `:stream`, `:chunks`. Defaults to `:plain`.
  - `:plain` - as binary.
  - `:stream` - as stream. If you don't want to close connection (because you want to reuse it later) pass `close_conn: false` in adapter opts.
  - `:chunks` - as chunks. You can get response body in chunks using `Tesla.Adapter.Mint.read_chunk/3` function.
  Processing of the chunks and checking body size must be done by yourself. Example of processing function is in `test/tesla/adapter/mint_test.exs` - `Tesla.Adapter.MintTest.read_body/4`. If you don't need connection later don't forget to close it with `Tesla.Adapter.Mint.close/1`.
- `:max_body` - Max response body size in bytes. Works only with `body_as: :plain`, with other settings you need to check response body size by yourself.
- `:conn` - Opened connection with mint. Is used for reusing mint connections.
- `:mode` - Mint receive mode. Defaults to `:passive` for connections opened by the adapter. When reusing a caller-supplied `:conn`, pass `:mode` explicitly if that connection is not `:active`.
- `:original` - Original host with port, for which reused connection was open. Needed for `Tesla.Middleware.FollowRedirects`. Otherwise adapter will use connection for another open host.
- `:close_conn` - Close connection or not after receiving full response body. Is used for reusing mint connections. Defaults to `true`.
- `:proxy` - Proxy settings. E.g.: `{:http, "localhost", 8888, []}`, `{:http, "127.0.0.1", 8888, []}`
- `:transport_opts` - Keyword list of HTTP or HTTPS options passed into `:gen_tcp` or `:ssl` respectively by mint. See [mint's docs on `transport_opts`](https://hexdocs.pm/mint/Mint.HTTP.html#connect/4-transport-options).

## read_chunk/3

Reads chunk of the response body.
Returns `{:fin, HTTP.t(), binary()}` if all body received, otherwise returns `{:nofin, HTTP.t(), binary()}`.