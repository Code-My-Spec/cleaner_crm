# Tesla.Middleware.SSE

Decode Server Sent Events.

This middleware is mostly useful when streaming response body.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([Tesla.Middleware.SSE, only: :data])
  end
end
```

## Options

- `:only` - keep only specified keys in event (necessary for using with `JSON` middleware)
- `:decode_content_types` - list of additional decodable content-types