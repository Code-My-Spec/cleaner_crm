# Tesla.Middleware.FollowRedirects

Follow HTTP 3xx redirects.

## Examples

```elixir
defmodule MyClient do
  def client do
  # defaults to 5
    Tesla.client([
      {Tesla.Middleware.FollowRedirects, max_redirects: 3}
    ])
  end
end
```

## Options

- `:max_redirects` - limit number of redirects (default: `5`)