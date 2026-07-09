# Tesla.Middleware.MethodOverride

Middleware that adds `X-HTTP-Method-Override` header with original request
method and sends the request as post.

Useful when there's an issue with sending non-POST request.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([Tesla.Middleware.MethodOverride])
  end
end
```

## Options

- `:override` - list of HTTP methods that should be overridden, everything except `:get` and `:post` if not specified