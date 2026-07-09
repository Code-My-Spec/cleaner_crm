# Tesla.Adapter.Gun

Adapter for [gun](https://github.com/ninenines/gun).

Remember to add `{:gun, "~> 1.3"}`, `{:idna, "~> 6.0"}` and `{:castore, "~> 0.1"}` to dependencies.

In version 1.3 gun sends `host` header with port. Fixed in master branch.
Also, you need to recompile tesla after adding `:gun` dependency:

```shell
mix deps.clean tesla
mix deps.compile tesla
```

## Examples

```elixir
# set globally in config/config.exs
config :tesla, :adapter, Tesla.Adapter.Gun

# set per module
defmodule MyClient do
  def client do
    Tesla.client([], Tesla.Adapter.Gun)
  end
end
```

## Adapter specific options

- `:timeout` - Time, while process, will wait for gun messages.

- `:body_as` - What will be returned in `%Tesla.Env{}` body key. Possible values:
    - `:plain` - as binary (default).
    - `:stream` - as stream.
        If you don't want to close connection (because you want to reuse it later)
        pass `close_conn: false` in adapter opts.
    - `:chunks` - as chunks.
        You can get response body in chunks using `Tesla.Adapter.Gun.read_chunk/3` function.

    Processing of the chunks and checking body size must be done by yourself.
    Example of processing function is in `test/tesla/adapter/gun_test.exs` - `Tesla.Adapter.GunTest.read_body/4`.
    If you don't need connection later don't forget to close it with `Tesla.Adapter.Gun.close/1`.

- `:max_body` - Max response body size in bytes.
    Works only with `body_as: :plain`, with other settings you need to check response body size by yourself.

- `:conn` - Opened connection pid with gun. Is used for reusing gun connections.

- `:close_conn` - Close connection or not after receiving full response body.
    Is used for reusing gun connections. Defaults to `true`.

- `:certificates_verification` - Add SSL certificates verification.
    [erlang-certifi](https://github.com/certifi/erlang-certifi)
    [ssl_verify_fun.erl](https://github.com/deadtrickster/ssl_verify_fun.erl)

- `:proxy` - Proxy for requests.
    **Socks proxy are supported from gun >= 2.0**.
    Examples: `{'localhost', 1234}`, `{{127, 0, 0, 1}, 1234}`, `{:socks5, 'localhost', 1234}`.

  **NOTE:** By default GUN uses TLS as transport if the specified port is 443,
    if TLS is required for proxy connection on another port please specify transport
    using the Gun options below otherwise tcp will be used.

- `:proxy_auth` - Auth to be passed along with the proxy opt.
    Supports Basic auth for regular and Socks proxy.
    Format: `{proxy_username, proxy_password}`.

## [Gun options](https://ninenines.eu/docs/en/gun/1.3/manual/gun/)

- `:connect_timeout` - Connection timeout.

- `:http_opts` - Options specific to the HTTP protocol.

- `:http2_opts` -  Options specific to the HTTP/2 protocol.

- `:protocols` - Ordered list of preferred protocols.
    Defaults: `[:http2, :http]`- for :tls, `[:http]` - for :tcp.

- `:trace` - Whether to enable dbg tracing of the connection process.
    Should only be used during debugging. Default: false.

- `:transport` - Whether to use TLS or plain TCP.
    The default varies depending on the port used.
    Port 443 defaults to tls. All other ports default to tcp.

- `:transport_opts` - Transport options.
    They are TCP options or TLS options depending on the selected transport.
    Default: `[]`. Gun version: 1.3.

- `:tls_opts` - TLS transport options.
    Default: `[]`. Gun from master branch.

- `:tcp_opts` - TCP transport options.
    Default: `[]`. Gun from master branch.

- `:socks_opts` - Options for socks.
    Default: `[]`. Gun from master branch.

- `:ws_opts` - Options specific to the Websocket protocol. Default: `%{}`.

    - `:compress` - Whether to enable permessage-deflate compression.
        This does not guarantee that compression will be used as it is the server
        that ultimately decides. Defaults to false.

    - `:protocols` - A non-empty list enables Websocket protocol negotiation.
        The list of protocols will be sent in the sec-websocket-protocol request header.
        The handler module interface is currently undocumented and must be set to `gun_ws_h`.

## read_chunk/3

Reads chunk of the response body.

Returns `{:fin, binary()}` if all body received, otherwise returns `{:nofin, binary()}`.