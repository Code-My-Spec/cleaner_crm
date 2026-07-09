# Tesla.Middleware.JSON

Encode requests and decode responses as JSON.

This middleware requires [Jason](https://hex.pm/packages/jason) (or other engine) as dependency.

Remember to add `{:jason, ">= 1.0"}` to dependencies.
Also, you need to recompile Tesla after adding `:jason` dependency:

```
mix deps.clean tesla
mix deps.compile tesla
```

> #### Using built-in `JSON` from Elixir 1.18 {: .info}
>
> This middleware supports the built-in `JSON` module introduced in ELixir 1.18, but for historical
> reasons is it not the default. To use it, set it as the `:engine`:
>
>     {Tesla.Middleware.JSON, engine: JSON}
>
> For more advanced usage using custom encoders/decodes, provide the `:encode` and `:decode` anonymous functions instead.

If you only need to encode the request body or decode the response body,
you can use `Tesla.Middleware.EncodeJson` or `Tesla.Middleware.DecodeJson` directly instead.

## Examples

```
defmodule MyClient do
  def client do
    Tesla.client([
      # use jason engine
      Tesla.Middleware.JSON,
      # or
      {Tesla.Middleware.JSON, engine: JSON}
      # or
      {Tesla.Middleware.JSON, engine: JSX, engine_opts: [strict: [:comments]]},
      # or
      {Tesla.Middleware.JSON, engine: Poison, engine_opts: [keys: :atoms]},
      # or
      {Tesla.Middleware.JSON, decode: &JSX.decode/1, encode: &JSX.encode/1}
    ])
  end
end
```

## Options

- `:decode` - decoding function
- `:encode` - encoding function
- `:encode_content_type` - content-type to be used in request header
- `:engine` - encode/decode engine, e.g `JSON`, `Jason`, `Poison` or `JSX`  (defaults to Jason)
- `:engine_opts` - optional engine options
- `:decode_content_types` - list of additional decodable content-types

## encode/2

Encode request body as JSON.

It is used by `Tesla.Middleware.EncodeJson`.

## decode/2

Decode response body as JSON.

It is used by `Tesla.Middleware.DecodeJson`.