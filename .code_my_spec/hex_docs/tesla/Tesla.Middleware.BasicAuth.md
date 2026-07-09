# Tesla.Middleware.BasicAuth

Basic authentication middleware.

[Wiki on the topic](https://en.wikipedia.org/wiki/Basic_access_authentication)

## Examples

```elixir
defmodule MyClient do
  def client(username, password, opts \ %{}) do
    Tesla.client([
      {Tesla.Middleware.BasicAuth,
        Map.merge(%{username: username, password: password}, opts)}
    ])
  end
end
```

## Options

- `:username` - username (defaults to `""`)
- `:password` - password (defaults to `""`)