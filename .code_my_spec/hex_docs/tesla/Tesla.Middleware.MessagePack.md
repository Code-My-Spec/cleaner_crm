# Tesla.Middleware.MessagePack

Encode requests and decode responses as MessagePack.

This middleware requires [Msgpax](https://hex.pm/packages/msgpax) as dependency.

Remember to add `{:msgpax, ">= 2.3.0"}` to dependencies.
Also, you need to recompile Tesla after adding `:msgpax` dependency:

```shell
mix deps.clean tesla
mix deps.compile tesla
```

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      Tesla.Middleware.MessagePack,
      # or
      {Tesla.Middleware.MessagePack, engine_opts: [binary: true]},
      # or
      {Tesla.Middleware.MessagePack, decode: &Custom.decode/1, encode: &Custom.encode/1}
    ])
  end
end
```

## Options

- `:decode` - decoding function
- `:encode` - encoding function
- `:encode_content_type` - content-type to be used in request header
- `:decode_content_types` - list of additional decodable content-types
- `:engine_opts` - optional engine options

## encode/2

Encode request body as MessagePack.

It is used by `Tesla.Middleware.EncodeMessagePack`.

## decode/2

Decode response body as MessagePack.

It is used by `Tesla.Middleware.DecodeMessagePack`.