# Tesla.Middleware.BearerAuth

Bearer authentication middleware.

Adds a `{"authorization", "Bearer <token>"}` header.

## Examples

```
defmodule MyClient do
  def new(token) do
    Tesla.client([
      {Tesla.Middleware.BearerAuth, token: token}
    ])
  end
end
```

## Options

- `:token` - token (defaults to `""`)